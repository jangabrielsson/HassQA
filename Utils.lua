---@diagnostic disable: undefined-global
HASS = HASS or {}
local fmt = string.format
function printf(fmt,...) print(fmt:format(...)) end
function color(col,fm,...)
  str = fmt(fm,...)
  return fmt('<font color="%s">%s</font>',col,str)
end
function printc(col,fm,...) print(color(col,fm,...)) end
fibaro.debugFlags = fibaro.debugFlags or {}
function DEBUGF(flag,fmt,...) 
  if fibaro.debugFlags[flag] then
    local str = fmt:format(...)
    quickApp:log(str)
    print(str)
  end
end
function ERRORF(f,...) 
  local str = fmt(f,...)
  quickApp:log("Error:"..str)
  fibaro.error(__TAG,color('red',"%s",str)) 
end
function WARNINGF(f,...) 
  local str = fmt(f,...)
  quickApp:log("Warning:"..str)
  fibaro.warning(__TAG,color('orange',"%s",str))
end

function table.member(t,v)
  for _,m in ipairs(t) do if m == v then return true end end
end
function table.copyShallow(t) -- shallow copy
  local r = {} for k,v in pairs(t) do r[k] = v end return r
end
function table.equal(e1,e2)
  if e1==e2 then return true
  else
    if type(e1) ~= 'table' or type(e2) ~= 'table' then return false
    else
      for k1,v1 in pairs(e1) do if e2[k1] == nil or not table.equal(v1,e2[k1]) then return false end end
      for k2,_  in pairs(e2) do if e1[k2] == nil then return false end end
      return true
    end
  end
end
local function copy(t) if type(t) ~= 'table' then return t end local r = {} for k,v in pairs(t) do r[k] = copy(v) end return r end
table.copy = copy

function math.round(v) return math.floor((tonumber(v) or 0)+0.5) end
function math.to100(v) return math.floor((v/255.0)*100+0.5) end
function math.to255(v) return math.floor((v/100.0)*255+0.5) end

if fibaro.fibemu then
  function PCALL(f,...) 
    return xpcall(f,function(err)
      ERRORF("%s",err) 
      print(os.debug.traceback())
      end,
    ...) 
  end
else
  function PCALL(f,...) return pcall(f,...) end
end

class 'WSConnection'
function WSConnection:__init(url,token)
  self.token = token
  self.url = fmt("ws://%s/api/websocket",url)
end

local pinger = nil
function WSConnection:ping()
  if pinger then
    clearTimeout(pinger)
    pinger = nil
  end
  pinger = setTimeout(function() 
    --print("PING") 
    self:send({type="ping"},function() self:ping() end)
  end,15*1000)
end

local mid,mcbs = 99,{}
function WSConnection:sendRaw(data)
  self.sock:send(json.encode(data))
  self:ping()
end

function WSConnection:send(data,cb)
  mid = mid + 1
  data.id = mid
  mcbs[mid] = {
    cb = cb,
    timeout = setTimeout(function() mcbs[mid] = nil end,5000) -- 5s timeout
  }
  self:sendRaw(data)
end

function WSConnection:serviceCall(domain, service, data, cb)
  self:send({type="call_service", domain=domain, service=service, service_data=data}, cb)
end

function WSConnection:connect()
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

getmetatable("").__idiv = function(str,len) return (#str < len or #str < 4) and str or str:sub(1,len-2)..".." end -- truncate strings

function string:capitalize()
  if self == "" then return self end
  return self:sub(1,1):upper()..self:sub(2)
end

function string.buff(b)
  local self,buff = {},b or {}
  function self.printf(fmt,...) table.insert(buff,fmt:format(...)) end
  function self.tostring()
    local str = table.concat(buff)
    local str2 = str:gsub("\n","<br>")
    str2 = str2:gsub("  ","&nbsp;&nbsp;")
    buff = {}
    return str
  end
  return self
end

local tmp_time = os.time()
local d1 = os.date("*t",  tmp_time)
local d2 = os.date("!*t", tmp_time)
d1.isdst = false
local zone_diff = os.difftime(os.time(d1), os.time(d2))
-- zone_diff value may be calculated only once (at the beginning of your program)

-- now we can perform the conversion (dt -> ux_time):
function os.utc2time(t)
  local dt = os.date("*t", t)
  dt.sec = dt.sec + zone_diff
  return os.time(dt)
end

function HASS.createEntityFilter()
  local self = {}
  local nodes = {}
  function self:add(path,val)
    local parts = path:split(".")
    local f
    if type(val)=='function' then 
      f = function(entity) return val(entity) end
    elseif type(val) == 'string' then 
      f = function(entity) return tostring(entity):match(val) end
    else f = function(entity) return val end end
    nodes[#nodes+1] = {path=parts,val=f}
  end
  local function skip0(entity,node,val)
    local ep = nil
    for _,part in ipairs(node) do
      entity = entity[part]
      if entity == nil then break end
    end
    if entity ~= nil then return val(entity) end 
  end
  function self:skip(entity)
    for _,node in ipairs(nodes) do
      if skip0(entity,node.path,node.val) then return true end
    end
    return false
  end
  setmetatable(self,{
    __newindex = function(t,k,v) self:add(k,v) end})
  return self
end

function HASS.createKeyList()
  local values = {}
  local self = { values = values}
  return setmetatable(self,{
    __newindex = function(t,k,v) values[#values+1]={key=k,value=v} end})
end