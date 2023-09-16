--- Stuff that should eventually be in SILE core in my opinion,
--- but isn't yet...

-- -----------------------------------------------------------------------

-- Annoyingly, inputters options can be nil.
-- Let be more tolerant and safe
local inputter = require("inputters.base")
local oldInit = inputter._init
function inputter:_init (options)
  oldInit(self, options)
  self.options = self.options or {}
end

-- -----------------------------------------------------------------------

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

-- -----------------------------------------------------------------------

local class = require("classes.plain")
local oldreg = class.registerCommands
function class:registerCommands()
  oldreg(self)

  -- Italic nesting.
  -- See https://github.com/sile-typesetter/sile/issues/1048
  -- The proposal there was to keep "em" and introduced "emph" as the nesting
  -- variant. But let's be more drastic and just make "em" nestable.
  -- We shouldn't care for compatibility with early defective designs.
  self:registerCommand("em", function (_, content)
    local style = SILE.settings:get("font.style")
    local toggle = (style and style:lower() == "italic") and "Regular" or "Italic"
    SILE.call("font", { style = toggle }, content)
  end)

  -- SILE's original centered and ragged environments do not allow nesting,
  -- i.e. they reset the left and/or right skips and thus apply to the full
  -- line width, loosing all margins.
  -- Say you have some nice indented block (margins on both sides), and you
  -- "center" something in it, then that centering goes past the block margins.
  -- That might be considered to be a "feature", but frankly, most people won't
  -- expect it.
  -- Paragraph indentation is another concern, it ought to be preserved in
  -- ragged left or right environments, but not in centered ones.
  -- Let's go for a full proper reimplementation of these environments.
  self:registerCommand("center", function (_, content)
    if #SILE.typesetter.state.nodes ~= 0 then
      SU.warn("\\center environment started after other nodes in a paragraph, may not center as expected")
    end
    SILE.settings:temporarily(function ()
      local lskip = SILE.settings:get("document.lskip") or SILE.nodefactory.glue()
      local rskip = SILE.settings:get("document.rskip") or SILE.nodefactory.glue()
      SILE.settings:set("document.parindent", SILE.nodefactory.glue())
      SILE.settings:set("current.parindent", SILE.nodefactory.glue())
      SILE.settings:set("document.lskip", SILE.nodefactory.hfillglue(lskip.width.length))
      SILE.settings:set("document.rskip", SILE.nodefactory.hfillglue(rskip.width.length))
      SILE.settings:set("typesetter.parfillskip", SILE.nodefactory.glue())
      SILE.settings:set("document.spaceskip", SILE.length("1spc", 0, 0))
      SILE.process(content)
      SILE.call("par")
    end)
  end, "Typeset its contents in a centered block (keeping margins).")

  self:registerCommand("raggedright", function (_, content)
    SILE.settings:temporarily(function ()
      local lskip = SILE.settings:get("document.lskip") or SILE.nodefactory.glue()
      local rskip = SILE.settings:get("document.rskip") or SILE.nodefactory.glue()
      SILE.settings:set("document.lskip", SILE.nodefactory.glue(lskip.width.length))
      SILE.settings:set("document.rskip", SILE.nodefactory.hfillglue(rskip.width.length))
      SILE.settings:set("typesetter.parfillskip", SILE.nodefactory.glue())
      SILE.settings:set("document.spaceskip", SILE.length("1spc", 0, 0))
      SILE.process(content)
      SILE.call("par")
    end)
  end, "Typeset its contents in a left aligned block (keeping margins).")

  self:registerCommand("raggedleft", function (_, content)
    SILE.settings:temporarily(function ()
      local lskip = SILE.settings:get("document.lskip") or SILE.nodefactory.glue()
      local rskip = SILE.settings:get("document.rskip") or SILE.nodefactory.glue()
      SILE.settings:set("document.lskip", SILE.nodefactory.hfillglue(lskip.width.length))
      SILE.settings:set("document.rskip", SILE.nodefactory.glue(rskip.width.length))
      SILE.settings:set("typesetter.parfillskip", SILE.nodefactory.glue())
      SILE.settings:set("document.spaceskip", SILE.length("1spc", 0, 0))
      SILE.process(content)
      SILE.call("par")
    end)
  end, "Typeset its contents in a right aligned block (keeping margins).")

  self:registerCommand("justified", function (_, content)
    SILE.settings:temporarily(function ()
      local lskip = SILE.settings:get("document.lskip") or SILE.nodefactory.glue()
      local rskip = SILE.settings:get("document.rskip") or SILE.nodefactory.glue()
      SILE.settings:set("document.lskip", SILE.nodefactory.glue(lskip.width.length))
      SILE.settings:set("document.rskip", SILE.nodefactory.glue(rskip.width.length))
      SILE.settings:set("document.spaceskip", nil)
      -- HACK. This knows too much about parfillskip defaults...
      -- (Which must be big, but smaller than infinity. Doh!)
      SILE.settings:set("typesetter.parfillskip", SILE.nodefactory.glue("0pt plus 10000pt"))
      SILE.process(content)
      SILE.call("par")
    end)
  end, "Typeset its contents in a justified block (keeping margins).")

  self:registerCommand("ragged", function (options, content)
    -- Fairly dumb command for dubious compatibility
    local l = SU.boolean(options.left, false)
    local r = SU.boolean(options.right, false)
    if l and r then
      SILE.call("center", {}, content)
    elseif r then
      SILE.call("raggedleft", {}, content)
    elseif l then
      SILE.call("raggedright", {}, content)
    else
      SILE.call("justified", {}, content)
    end
  end)

  self:registerCommand("rightalign", function (_, content)
    -- Honestly, why would we need this stupid and redundant command?
    -- It's not even a standard LaTeX command.
    -- We don't even have leftalign to go with it.
    SU.warn("rightalign ought to be deprecated. Use raggedleft instead.")
    SILE.call("raggedleft", {}, content)
  end)
end

-- -----------------------------------------------------------------------

-- See https://github.com/sile-typesetter/sile/issues/1875
-- Remove warning when file is not found and let the caller handle errors.
function SILE.resolveFile (filename, pathprefix)
  local candidates = {}
  -- Start with the raw file name as given prefixed with a path if requested
  if pathprefix then candidates[#candidates+1] = pl.path.join(pathprefix, "?") end
  -- Also check the raw file name without a path
  candidates[#candidates+1] = "?"
  -- Iterate through the directory of the master file, the SILE_PATH variable, and the current directory
  -- Check for prefixed paths first, then the plain path in that fails
  if SILE.masterDir then
    for path in SU.gtoke(SILE.masterDir..";"..tostring(os.getenv("SILE_PATH")), ";") do
      if path.string and path.string ~= "nil" then
        if pathprefix then candidates[#candidates+1] = pl.path.join(path.string, pathprefix, "?") end
        candidates[#candidates+1] = pl.path.join(path.string, "?")
      end
    end
  end
  -- Return the first candidate that exists, also checking the .sil suffix
  local path = table.concat(candidates, ";")
  local resolved, err = package.searchpath(filename, path, "/")
  if resolved then
    if SILE.makeDeps then SILE.makeDeps:add(resolved) end
  -- else
  --   SU.warn(("Unable to find file '%s': %s"):format(filename, err))
  end
  return resolved
end
