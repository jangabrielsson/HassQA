---@diagnostic disable: undefined-global

-- Example of a user module, with own classes
function MODULE_1classes()

  class 'WindSensor'(HASSChild)
  function WindSensor:__init(dev)
    HASSChild.__init(self,dev)
  end
  -- Works with entity_id like weather.forecast_home
  function WindSensor:update(entity)
    local attr = entity.attributes
    self:updateProperty("value", tonumber(attr.wind_speed) or 0) -- no attr, set 0
  end

  HASS.classes.WindSensor = { -- Register WindSensor class in classes table
    type = 'com.fibaro.windSensor',
  }

  HASS.customTypes['^weather%.'] = function(e) 
    if e.attributes.wind_speed then return 'weather_wind_speed' end
  end
  HASS.classes.WindSensor.auto='weather_wind_speed' 
  
  HASS.classes.CurrTemperature = { -- Register CurrTemperature class in classes table
    type = 'com.fibaro.temperatureSensor',
  }

  class 'CurrTemperature'(HASSChild)
  function CurrTemperature:__init(dev)
    HASSChild.__init(self,dev)
  end
  function CurrTemperature:update(entity)
    local attr = entity.attributes
    self:updateProperty("value", attr.current_temperature or 0) -- no attr, set 0
  end

  HASS.customTypes['^climate%.'] = function(e) 
    if e.attributes.hvac_modes then return 'climate_hvac' end
  end

  HASS.classes.Thermostat.auto = 'climate_hvac'


  --[[
  Ex. in Config
  

  --]]
end
