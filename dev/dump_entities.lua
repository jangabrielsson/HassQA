---@diagnostic disable: undefined-global
-- Dump all entities from the real HASS into dev/hass_entities_local.json
-- (one entity per line, keyed and sorted by entity_id).
--
--   flua --api local dev/dump_entities.lua        (run from the repo root)
--
-- Uses the same credential chain as the HASS QA (config.HASS_url/_token from
-- .flua.lua / ~/.flua.lua / ~/.plua/config.lua).
--
-- The output file is GITIGNORED on purpose: a full dump contains private data
-- (names, trackers, zones). Known-sensitive attributes are redacted anyway,
-- but review entities manually before curating them into the committed
-- dev/hass_entities.json examples file.
--%%name:DumpEntities
--%%type:com.fibaro.deviceController
--%%mode:offline
--%%var:url=config.HASS_url
--%%var:token=config.HASS_token

local OUTPUT = "dev/hass_entities_local.json"
local REDACT = { -- attribute keys whose values never belong in a dump
  access_token=true, token=true, entity_picture=true,
  latitude=true, longitude=true, gps_accuracy=true,
}

local function redact(t)
  if type(t) ~= 'table' then return t end
  local r = {}
  for k,v in pairs(t) do
    if REDACT[k] then r[k] = "<redacted>" else r[k] = redact(v) end
  end
  return r
end

function QuickApp:onInit()
  local qvar = {}
  for _,v in ipairs(self.properties.quickAppVariables or {}) do qvar[v.name] = v.value end
  local url,token = qvar.url,qvar.token
  if not (url and token) then
    print("Missing HASS_url/HASS_token in the config chain (.flua.lua / ~/.flua.lua)")
    return _FLUA.exit(1)
  end
  print("Fetching entities from "..url.." ...")
  net.HTTPClient():request("http://"..url.."/api/states",{
    options = {
      method = 'GET',
      headers = { Authorization = "Bearer "..token, ["Content-Type"] = "application/json" },
      timeout = 15000,
    },
    success = function(resp)
      if resp.status ~= 200 then
        print("HASS answered HTTP "..tostring(resp.status))
        return _FLUA.exit(1)
      end
      local states = json.decode(resp.data)
      local ids,byId,domains = {},{},{}
      for _,e in ipairs(states) do
        ids[#ids+1] = e.entity_id
        byId[e.entity_id] = redact(e)
        local domain = e.entity_id:match("^(.-)%.") or "?"
        domains[domain] = (domains[domain] or 0)+1
      end
      table.sort(ids)
      local out = {"{"}
      for i,id in ipairs(ids) do
        out[#out+1] = string.format('%q: %s%s',id,json.encode(byId[id]),
          i < #ids and "," or "")
      end
      out[#out+1] = "}"
      local f = io.open(OUTPUT,"w")
      if not f then
        print("Cannot write "..OUTPUT.." (run from the repo root)")
        return _FLUA.exit(1)
      end
      f:write(table.concat(out,"\n"))
      f:close()
      print(string.format("Wrote %d entities to %s",#ids,OUTPUT))
      local ds = {}
      for d,n in pairs(domains) do ds[#ds+1] = string.format("%s:%d",d,n) end
      table.sort(ds)
      print("Domains: "..table.concat(ds,", "))
      _FLUA.exit(0)
    end,
    error = function(err)
      print("Request failed: "..tostring(err))
      _FLUA.exit(1)
    end,
  })
end
