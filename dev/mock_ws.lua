---@diagnostic disable: undefined-global
-- Mock HASS websocket server for offline tests.
-- Replaces net.WebSocketClient and answers auth/get_states/subscribe_events.
MOCK = {
  authCount = 0,
  getStatesCount = 0,
  serviceCalls = {},
  sock = nil,
  answerPings = true, -- set false to simulate a half-open connection
}

local function mkState(id,state,attrs)
  return {entity_id=id, state=state, attributes=attrs or {}}
end

MOCK.states = {
  mkState("light.test","off",{friendly_name="Test light"}),
  mkState("sensor.temp_test","21.5",
    {friendly_name="Temp test", device_class="temperature", unit_of_measurement="°C"}),
}

function MOCK.receive(data) -- push a server message to the QA
  MOCK.sock.listeners.dataReceived(json.encode(data))
end

-- Example HASS entity payloads collected in dev/hass_entities.json,
-- keyed by entity_id. Run tests from the repo root.
function MOCK.loadEntityExamples(path)
  path = path or "dev/hass_entities.json"
  local f = io.open(path,"r") or io.open("hass_entities.json","r")
  assert(f,"cannot open "..path.." (run from the repo root)")
  local data = f:read("*a")
  f:close()
  return json.decode(data)
end

function MOCK.stateChanged(new_state,old_state)
  MOCK.receive({type="event",
    event={data={entity_id=new_state.entity_id, new_state=new_state, old_state=old_state}}})
end

function MOCK.entityRemoved(entity_id,old_state) -- HASS sends new_state = null
  MOCK.receive({type="event",
    event={data={entity_id=entity_id, old_state=old_state}}})
end

function MOCK.disconnect()
  MOCK.sock.listeners.disconnected("mock","closed")
end

local function onSend(data)
  if data.type == "auth" then
    MOCK.authCount = MOCK.authCount + 1
    MOCK.receive({type="auth_ok"})
  elseif data.type == "get_states" then
    MOCK.getStatesCount = MOCK.getStatesCount + 1
    MOCK.receive({id=data.id, type="result", success=true, result=MOCK.states})
  elseif data.type == "subscribe_events" then
    MOCK.receive({id=data.id, type="result", success=true})
  elseif data.type == "ping" then
    if MOCK.answerPings then
      MOCK.receive({id=data.id, type="pong"})
    end
  elseif data.type == "call_service" then
    MOCK.serviceCalls[#MOCK.serviceCalls+1] = data
    MOCK.receive({id=data.id, type="result", success=true})
  end
end

function net.WebSocketClient()
  local self = {listeners = {}}
  MOCK.sock = self
  function self:addEventListener(ev,f) self.listeners[ev] = f end
  function self:connect(_url)
    setTimeout(function()
      if self.listeners.connected then self.listeners.connected() end
      MOCK.receive({type="auth_required"})
    end,0)
  end
  function self:send(data) onSend(json.decode(data)) end
  function self:close() self.closed = true end -- local close: no disconnected event
  return self
end
