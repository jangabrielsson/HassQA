---@diagnostic disable: undefined-global
-- Offline regression test: a half-open connection (pings unanswered) must be
-- detected via pong timeout and trigger a reconnect, with subscriptions intact.
-- Run: flua --api local --instant dev/test_pong.lua
--%%name:TestHASSPong
--%%type:com.fibaro.deviceController
--%%mode:offline
--%%var:url="127.0.0.1:8123"
--%%var:token="mock-token"
--%%var:auto="false"
--%%var:debug="main,wsc"

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
      if tries > 1200 then -- ping(15s)+pong timeout(10s)+reconnect(5s) ≈ 30 virtual s
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

  -- Go half-open: the socket stays "up" but the server stops answering pings.
  -- No disconnected event will ever arrive; only the pong timeout can save us.
  MOCK.answerPings = false
  local authBefore = MOCK.authCount
  poll(function() return MOCK.authCount > authBefore end,step3,
    "pong-timeout reconnect (no disconnect event)")
end

function step3()
  MOCK.answerPings = true
  t:expect(HASS.entities["light.test"] == e1,"entity object survives pong-timeout reconnect")
  local n = sub.n
  MOCK.stateChanged({entity_id="light.test", state="on",
    attributes={friendly_name="Test light"}})
  t:expect(sub.n > n,"subscriber still receives events after pong-timeout reconnect")
  t:assert_eq(sub.last,"on","state updated after reconnect")
  t:finish()
end

setTimeout(function()
  poll(function() return quickApp and quickApp._initialized end,step2,"QA initialization")
end,0)
