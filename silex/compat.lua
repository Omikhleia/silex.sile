--- Compatibility layer
-- Stuff we had in various "Omikhleia" packages, that we need to keep working
-- with earlier versions of SILE.

-- Loosely inspired from https://github.com/kikito/semver.lua
-- (MIT License (c) 2011 Enrique García Cota)
-- but simplified to our bare needs.
local semver = {}
local mt = {}
function mt:__eq(other)
  return self.major == other.major and
          self.minor == other.minor and
          self.patch == other.patch
end
function mt:__lt(other)
  if self.major ~= other.major then return self.major < other.major end
  if self.minor ~= other.minor then return self.minor < other.minor end
  if self.patch ~= other.patch then return self.patch < other.patch end
  return false
end
function mt:__le(other)
  if self.major ~= other.major then return self.major <= other.major end
  if self.minor ~= other.minor then return self.minor <= other.minor end
  if self.patch ~= other.patch then return self.patch <= other.patch end
  return true
end
function mt:__tostring()
  return ("%d.%d.%d"):format(self.major, self.minor, self.patch)
end
local function new(vstr)
  local major, minor, patch = vstr:match("^v?(%d+)%.(%d+)%.(%d+)")
  local result = { major = tonumber(major), minor = tonumber(minor), patch = tonumber(patch) }
  if not result.major and not result.minor and not result.patch then
    SU.error("Invalid version string: "..vstr)
  end
  local o = setmetatable(result, mt)
  return o
end
setmetatable(semver, { __call = function(_, ...) return new(...) end })

local SILEVERSION = semver(SILE.version)

-- Compat: content pos stripping utility
if SU.stripContentPos then
  SU.debug("silex", "No need for patching utilities (AST position stripping)")
else
  SU.debug("silex", "Patching utilities (AST position stripping from SILE 0.14.9)")
  if SILEVERSION >= semver("0.14.9") then
    SU.warn("SILE version "..SILE.version.." should not have needed patching AST position stripping")
  end

  SU.stripContentPos = function (content)
    if type(content) ~= "table" then
      return content
    end
    local stripped = {}
    for k, v in pairs(content) do
      if type(v) == "table" then
        v = SU.stripContentPos(v)
      end
      stripped[k] = v
    end
    if content.id or content.command then
      stripped.pos, stripped.col, stripped.lno = nil, nil, nil
    end
    return stripped
  end
end

-- Compat: issues fixed in 0.14.9
-- No easy way to do feature detection, so we just check the version.
if SILEVERSION < semver("0.14.9") then
  SU.debug("silex", "Patching pre-0.14.9 issues")
  SILE.settings.declare = function (self, spec)
    if self.declarations[spec.parameter] then -- HACK
      return SU.debug("silex", "Settings redeclaration ignored ", spec.parameter)
    end
    self.declarations[spec.parameter] = spec
    self:set(spec.parameter, spec.default, true)
  end

  -- See https://github.com/sile-typesetter/sile/pull/1765
  local infinity = SILE.measurement(1e13)
  function SILE.nodefactory.hfillglue:_init (spec)
    self:super(spec)
    self.width = SILE.length(self.width.length, infinity, self.width.shrink)
  end
  function SILE.nodefactory.hssglue:_init (spec)
    self:super(spec)
    self.width = SILE.length(self.width.length, infinity, infinity)
  end
  function SILE.nodefactory.vfillglue:_init (spec)
    self:super(spec)
    self.height = SILE.length(self.width.length, infinity, self.width.shrink)
  end
  function SILE.nodefactory.vssglue:_init (spec)
    self:super(spec)
    self.height = SILE.length(self.width.length, infinity, infinity)
  end
else
  SU.debug("silex", "No need for patching pre-0.14.9 issues")
end
