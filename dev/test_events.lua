---@diagnostic disable: undefined-global
-- Offline regression test: event-handler hardening.
--  * removed entities (new_state == null) must not crash and must be dropped
--  * late entities must respect the entityFilter
-- Run: flua --api local --instant dev/test_events.lua
--%%name:TestHASSEvents
--%%type:com.fibaro.deviceController
--%%mode:offline
--%%var:url="127.0.0.1:8123"
--%%var:token="mock-token"
--%%var:auto="false"
--%%var:debug="main,late"

--%%file:$qwikchild.lua,QChild
--%%file:mock_ws.lua,mock
--%%file:../Utils.lua,utils
--%%file:../Classes.lua,classes
--%%file:../Config.lua,config
--%%file:../User.lua,User
--%%file:../HASS.lua,hass

--%%u:{label="title",text="Label (Title)"}
--%%u:{label="qaInfo",text="QA info"}
--%%u:{label="logLabel",text=""}

local Test = require("flua-test")
local t = Test.new()

local function poll(cond,next,desc)
  local tries = 0
  local function check()
    if cond() then next()
    else
      tries = tries+1
      if tries > 200 then
        t:expect(false,"timeout waiting for "..desc)
        t:finish()
      else setTimeout(check,50) end
    end
  end
  check()
end

local sub = {n=0, last=nil}
function sub:change(entity) self.n = self.n+1 self.last = entity.state end

local function run()
  -- Late entity that does NOT match the filter: gets created
  MOCK.stateChanged({entity_id="switch.late", state="on",
    attributes={friendly_name="Late switch"}})
  t:expect(HASS.entities["switch.late"] ~= nil,"late entity created")

  -- Late entity that matches the filter (^update%.): must be skipped
  MOCK.stateChanged({entity_id="update.sneaky", state="on",
    attributes={friendly_name="Sneaky update"}})
  t:expect(HASS.entities["update.sneaky"] == nil,"filtered late entity not created")
  MOCK.stateChanged({entity_id="update.sneaky", state="off",
    attributes={friendly_name="Sneaky update"}})
  t:expect(HASS.entities["update.sneaky"] == nil,"filtered late entity stays skipped")

  -- Removal of a known, subscribed entity: no crash, subscribers told, entity dropped
  local e = HASS.entities["light.test"]
  t:expect(e ~= nil,"light.test entity created at startup")
  e:subscribe(sub)
  local n = sub.n
  MOCK.entityRemoved("light.test",{entity_id="light.test", state="off", attributes={}})
  t:expect(sub.n > n,"subscriber notified on removal")
  t:assert_eq(sub.last,"unavailable","removed entity reported unavailable")
  t:expect(HASS.entities["light.test"] == nil,"removed entity dropped")

  -- Removal of an unknown entity: must be a no-op, not an error/crash
  MOCK.entityRemoved("sensor.ghost",{entity_id="sensor.ghost", state="0", attributes={}})
  t:expect(HASS.entities["sensor.ghost"] == nil,"unknown removal is a no-op")

  -- The handler must still be alive: a normal event still works
  MOCK.stateChanged({entity_id="switch.late", state="off",
    attributes={friendly_name="Late switch"}})
  t:assert_eq(HASS.entities["switch.late"].state,"off","handler still processes events")

  t:finish()
end

setTimeout(function()
  poll(function() return quickApp and quickApp._initialized end,run,"QA initialization")
end,0)
