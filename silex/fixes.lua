-- Annoyingly, inputters options can be nil
local inputter = require("inputters.base")
local oldInit = inputter._init
function inputter:_init (options)
  oldInit(self, options)
  self.options = self.options or {}
end
