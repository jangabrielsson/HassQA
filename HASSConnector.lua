local fmt = string.format

--[[
  HASSConnection - WebSocket connection to Home Assistant
  This class handles the connection to Home Assistant's WebSocket API.

  local con = HASSConnection("192.168.1.67","my_token")
  con:connect()

  con:serviceCall("light","turn_on",{entity_id="light.living_room"},function() print("Light turned on") end)
  con:send({type="call_service", domain="light", service="turn_on", service_data={entity_id="light.living_room"}})
  con:send({type="call_service", domain="light", service="turn_on", service_data={entity_id="light.living_room"}})
  con:send({type="call_service", domain="light", service="turn_on", service_data={entity_id="light.living_room"}})
  con:send({type="call_service", domain="light", service="turn_on", service_data={entity_id="light.living_room"}})
  con:send({type="call_service", domain="light", service="turn_on", service_data={entity_id="light.living_room"}})

--]]

class 'HASSConnection'
HASSConnection = HASSConnection
function HASSConnection:__init(url,token)
  self.token = token
  self.url = fmt("ws://%s/api/websocket",url)
end

local mid,mcbs = 99,{}

local pinger = nil
function HASSConnection:ping()
  if pinger then
    pinger = clearTimeout(pinger)
  end
  pinger = setTimeout(function() 
    self:send({type="ping"},function() self:ping() end)
  end,15*1000)
end

function HASSConnection:sendRaw(data)
  self.sock:send(json.encode(data))
  self:ping()
end

function HASSConnection:send(data,cb)
  mid = mid + 1
  data.id = mid
  mcbs[mid] = {
    cb = cb,
    timeout = setTimeout(function() mcbs[mid] = nil end,5000) -- 5s timeout
  }
  self:sendRaw(data)
end

function HASSConnection:serviceCall(domain, service, data, cb)
  self:send({type="call_service", domain=domain, service=service, service_data=data}, cb)
end

function HASSConnection:connect()
  DEBUGF('wsc',"Websocket connect")
  local function handleConnected()
    DEBUGF('wsc',"Connected")
  end

  local function connect()
    DEBUGF('wsc',"Connect: %s",self.url)
    self.sock:connect(self.url)
  end

  local function handleDisconnected(a,b)
    WARNINGF("Disconnected - will reconnect in 5s")
    setTimeout(function() connect() end,5000)
  end
  local function handleError(err)
    ERRORF("Error: %s", err)
  end
  local nEvents = 0
  local function handleDataReceived(data)
    nEvents = nEvents+1
    data = json.decode(data)
    if data.id and mcbs[data.id] then
      local cb,timeout = mcbs[data.id].cb,mcbs[data.id].timeout
      mcbs[data.id] = nil
      if timeout then clearTimeout(timeout) end
      if cb then 
        local stat,err = PCALL(cb,data) 
        if not stat then ERRORF("Callback error: %s",err) end
      else print(json.encode(data)) end
      return
    end
    if self.msgHandler then self:msgHandler(data)
    else
      DEBUGF('wsc',"Unknown message type: %s",data.type)
    end
  end
  self.sock = net.WebSocketClient()
  self.sock.timeout=0
  self.sock:addEventListener("connected", handleConnected)
  self.sock:addEventListener("disconnected", handleDisconnected)
  self.sock:addEventListener("error", handleError)
  self.sock:addEventListener("dataReceived", handleDataReceived)

  connect()
end
