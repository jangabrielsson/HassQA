---@diagnostic disable: undefined-global
-- Offline regression test: child QA fixes.
--  * Fan:update must reach the child's properties (was: crash on undefined 'd')
--  * Thermostat with no climate_hvac entity must not crash on init
-- Run: flua --api local --instant dev/test_children.lua
--%%name:TestHASSChildren
--%%type:com.fibaro.deviceController
--%%mode:offline
--%%var:url="127.0.0.1:8123"
--%%var:token="mock-token"
--%%var:auto="false"
--%%var:debug="main"

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

MOCK.states[#MOCK.states+1] = {entity_id="fan.test", state="on",
  attributes={friendly_name="Test fan", percentage=50}}

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

local function run()
  -- Fan child: the entity state must reach the child's properties
  local fanChild = quickApp:newChildQA("uid_fan","Fan test",nil,{"fan.test"},"Fan")
  t:expect(fanChild ~= nil,"fan child created")
  setTimeout(function() -- subscription fires on a 0-timer, give it a tick
    local dev = api.get("/devices/"..fanChild.id)
    t:assert_eq(dev.properties.value,"on","fan state reached child property")

    -- Thermostat without a climate_hvac entity: init must not blow up
    local ok,err = pcall(function()
      return quickApp:newChildQA("uid_thermo","Thermo test",nil,
        {"sensor.temp_test"},"Thermostat")
    end)
    t:expect(ok,"thermostat with missing climate entity does not crash: "..tostring(err))
    t:finish()
  end,100)
end

setTimeout(function()
  poll(function() return quickApp and quickApp._initialized end,run,"QA initialization")
end,0)
