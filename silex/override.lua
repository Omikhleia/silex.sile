local originalRequire = require

local loaded = {}

SU.debug("silex", "Overriding require global function")
require = function (name) -- luacheck: ignore
  if loaded[name] then return loaded[name] end
  local ok, mod = pcall(originalRequire, "silex." .. name)
  if ok then
    if not loaded[name] then
      loaded[name] = mod
      SU.debug("silex", "Loaded silex version of " .. name)
    end
    return mod
  end
  loaded[name] = originalRequire(name)
  return loaded[name]
end
