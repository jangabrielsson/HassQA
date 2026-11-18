-- Project luacheck config: `luacheck src/ dev/` from the repo root.
-- (flua --tool luacheck currently uses its own generated config; this file
--  is for running luacheck directly, e.g. in CI.)
--
-- NOTE: run all files in ONE invocation — `allow_defined = true` lets a
-- global defined in one file of the QA closure (Utils defines DEBUGF,
-- HASS.lua defines quickApp, ...) be used from the others, while truly
-- undefined globals still flag.
std = "lua54"

-- flua/HC3 runtime globals a QA may use without defining
read_globals = {
  "api", "mqtt", "json",
  "QuickAppChild", "QwikAppChild",
  "plugin", "hub", "_FLUA", "__TAG",
  "__assert_type", "urlencode",
  "setTimeout", "clearTimeout", "setInterval", "clearInterval",
  "_sceneId", "sourceTrigger", "RefreshStateSubscriber",
  "class", "util", "require",
}

globals = {
  -- intentionally extended by Utils.lua
  "table", "math", "string", "os",
  -- runtime tables the QA owns/extends (QuickApp gets methods defined on it)
  "QuickApp", "fibaro", "net", "HASS", "quickApp",
  -- `class 'X'` creates globals via a function call, which
  -- allow_defined cannot see — list the QA's classes explicitly
  "WSConnection", "Entity", "HASSChild",
  "DimLight", "RGBLight", "XYLight", "BinarySwitch", "BinarySensor",
  "Switch", "Button", "Rotary", "Speaker", "TV", "Motion", "Lux",
  "DoorSensor", "WindowSensor", "DoorLock", "Temperature", "SmokeSensor",
  "Humidity", "Pm25", "Pm10", "Pm1", "Co2", "Co", "Measurement", "Problem",
  "Fan", "DeviceTracker", "Cover", "Thermostat", "Calendar", "Zone",
  "InputText",
  -- user-module classes (src/User.lua)
  "WindSensor", "CurrTemperature",
}

allow_defined = true
max_line_length = false

ignore = {
  "212", -- unused argument (callback/handler signatures)
  "131", -- unused implicitly defined global (QuickApp methods called by the HC3/UI)
  "61",  -- whitespace style (611-614)
  "42", "43", -- shadowing locals/upvalues (idiomatic here: fmt, self)
}
