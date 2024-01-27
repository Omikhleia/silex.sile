local originalRequire = require

local loaded = {}

SU.debug("silex", "Overriding require global function")
require = function (name) -- luacheck: ignore
  if loaded[name] then return loaded[name] end
  local ok, mod = pcall(originalRequire, "silex." .. name)
  if ok then
    if not loaded[name] then
      loaded[name] = mod
      SU.debug("silex", "Loaded silex version of", name)
    end
    return mod
  end
  loaded[name] = originalRequire(name)
  return loaded[name]
end

if SILE.outputters then
  -- Outputters are loaded before the override, at SILE.init().
  -- We come late to the party, so we need to reload them for our override to work.
  -- Is this fragile? Yes. Is it a hack? Yes. Does it work? Yes.
  for k, _ in pairs(SILE.outputters) do
    SU.debug("silex", "Re-loading outputter", k)
    SILE.outputters[k] = require("outputters." .. k)
  end
  if SILE.outputter then
    SU.debug("silex", "Re-instanciating current outputter", SILE.outputter._name)
    SILE.outputter = SILE.outputters[SILE.outputter._name]()
  end
end
