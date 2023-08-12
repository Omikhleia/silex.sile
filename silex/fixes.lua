--- Stuff that should eventually be in SILE core in my opinion,
--- but isn't yet...

-- Annoyingly, inputters options can be nil
local inputter = require("inputters.base")
local oldInit = inputter._init
function inputter:_init (options)
  oldInit(self, options)
  self.options = self.options or {}
end

-- Greek numbering ("greek") for counters, similar to "alpha".
-- There are books where one wants to number items with Greek letters in
-- sequence, e.g. annotations in biblical material etc.
-- as in α β γ δ ε ζ η θ ι κ λ μ ν ξ ο π ρ σ τ υ φ χ ψ ω.
-- We can't use ICU "grek" or "greklow" numbering systems because they are
-- arithmetic e.g. 6 is a digamma, 11 is iota alpha, etc. and all followed by
-- a numeric marker (prime-like symbol).
local luautf8 = require("lua-utf8")
SU.formatNumber.und.greek = function(num)
  local out = ""
  local a = SU.codepoint("α") -- alpha
  if num < 18 then
    -- alpha to rho
    out = luautf8.char(num + a - 1)
  elseif num < 25 then
    -- sigma to omega (unicode has two sigmas here, we skip one)
    out = luautf8.char(num + a)
  else
    -- Don't try to be too clever
    SU.error("Greek numbering is only supported up to 24")
  end
  return out
end
