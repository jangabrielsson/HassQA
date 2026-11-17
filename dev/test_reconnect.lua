---@diagnostic disable: undefined-global
-- Offline regression test: entity subscriptions must survive a websocket reconnect.
-- Run: flua --api local --instant dev/test_reconnect.lua
--%%name:TestHASSReconnect
--%%type:com.fibaro.deviceController
--%%mode:offline
--%%var:url="127.0.0.1:8123"
--%%var:token="mock-token"
--%%var:auto="false"
--%%var:debug="main,wsc,late"

--%%file:$qwikchild.lua,QChild
--%%file:mock_ws.lua,mock
--%%file:../Utils.lua,utils
--%%file:../Classes.lua,classes
--%%file:../Config.lua,config
--%%file:../User.lua,User
--%%file:../HASS.lua,hass

--%%u:{label="title",text="Label (Title)"}
--%%u:{label="label_ID_2",text="QuickAppChildren:"}
--%%u:{select="qaSelect",text="QuickAppChild",visible=true,onToggled="qaSelected",options={}}
--%%u:{select="classSelect",text="Class",visible=true,onToggled="classSelected",options={}}
--%%u:{label="qaInfo",text="QA info"}
--%%u:{multi="entitySelect",text="Entities",visible=true,onToggled="entitySelected",options={}}
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

local e1
local step2,step3

function step2()
  e1 = HASS.entities["light.test"]
  t:expect(e1 ~= nil,"light.test entity created at startup")
  if not e1 then return t:finish() end
  e1:subscribe(sub)
  t:assert_eq(sub.n,1,"subscribe delivers initial state")
  MOCK.stateChanged({entity_id="light.test", state="on",
    attributes={friendly_name="Test light"}})
  t:assert_eq(sub.n,2,"state_changed event delivered before disconnect")
  t:assert_eq(sub.last,"on","entity state updated before disconnect")

  local authBefore,statesBefore = MOCK.authCount,MOCK.getStatesCount
  MOCK.disconnect() -- simulate HASS restart / network blip
  poll(function()
    return MOCK.authCount > authBefore and MOCK.getStatesCount > statesBefore
  end,step3,"re-authentication after disconnect")
end

function step3()
  t:expect(HASS.entities["light.test"] == e1,
    "entity object survives reconnect (not replaced)")
  local n = sub.n
  MOCK.stateChanged({entity_id="light.test", state="off",
    attributes={friendly_name="Test light"}})
  t:expect(sub.n > n,"subscriber still receives events after reconnect")
  t:assert_eq(sub.last,"off","entity state updated after reconnect")
  t:finish()
end

setTimeout(function()
  poll(function() return quickApp and quickApp._initialized end,step2,"QA initialization")
end,0)
