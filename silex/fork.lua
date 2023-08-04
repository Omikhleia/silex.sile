-- HACKS FOR MULTIPLE INSTANTION SIDE EFFECTS
-- OPINIONATED DEPARTURE FROM SILE.
-- ... but just run SILE with -d resilient... and wonder WHY we
-- keep redefining things in obscure places.
-- See https://github.com/sile-typesetter/sile/issues/1531
-- Since August 2021 (initial effort porting my 0.12.5 packages to 0.14.x),
-- I have struggled with it. I can't make sense of it now in Feb. 2023, so
-- moving on and cancelling it...
SU.debug("silex", "Patching core for multiple instantiation side effects")

local class = require("classes.plain")
function class:loadPackage (packname, options)
  local pack = require(("packages.%s"):format(packname))
  if type(pack) == "table" and pack.type == "package" then -- new package
    -- HACK
    -- I beg to disagree with SILE here
    if self.packages[pack._name] then
      return SU.debug("silex", "Ignoring package already loaded in the class:", pack._name)
    end
    self.packages[pack._name] = pack(options)
  else -- legacy package
    SU.warn("CLASS: legacy package "..pack._name)
    self:initPackage(pack, options)
  end
end

SILE.use = function (module, options)
  local pack
  if type(module) == "string" then
    pack = require(module)
  elseif type(module) == "table" then
    pack = module
  end
  local name = pack._name
  local class = SILE.documentState.documentClass -- luacheck: ignore
  if not pack.type then
    SU.error("Modules must declare their type")
  elseif pack.type == "class" then
    SILE.classes[name] = pack
    if class then
      SU.error("Cannot load a class after one is already instantiated")
    end
    SILE.scratch.class_from_uses = pack
  elseif pack.type == "inputter" then
    SILE.inputters[name] = pack
    SILE.inputter = pack(options)
  elseif pack.type == "outputter" then
    SILE.outputters[name] = pack
    SILE.outputter = pack(options)
  elseif pack.type == "shaper" then
    SILE.shapers[name] = pack
    SILE.shaper = pack(options)
  elseif pack.type == "typesetter" then
    SILE.typesetters[name] = pack
    SILE.typesetter = pack(options)
  elseif pack.type == "pagebuilder" then
    SILE.pagebuilders[name] = pack
    SILE.pagebuilder = pack(options)
  elseif pack.type == "package" then
    SILE.packages[name] = pack
    -- HACK
    -- I also beg to disagree with SILE here
    if class then
      if class.packages[name] then
        return SU.debug("silex", "\\use fork ignoring already loaded package:", name)
      end
      class.packages[name] = pack(options)
    else
      table.insert(SILE.input.preambles, {
        pack = pack,
        options = options
      })
    end
  end
end
