SILE.X = SILE.X or {}

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

-- Compat: parindent issue
if SILEVERSION >= semver("0.14.9") then
  SU.debug("silex", "No need for patching SILE (parindent issue)")
else
  SU.debug("silex", "Patching SILE (parindent issue)")

  local class = require("classes.plain")
  function class.newPar (typesetter)
    local parindent = SILE.settings:get("current.parindent") or SILE.settings:get("document.parindent")
    typesetter:pushGlue(parindent:absolute()) -- HACK
    SILE.settings:set("current.parindent", nil)
    local hangIndent = SILE.settings:get("current.hangIndent")
    if hangIndent then
      SILE.settings:set("linebreak.hangIndent", hangIndent)
    end
    local hangAfter = SILE.settings:get("current.hangAfter")
    if hangAfter then
      SILE.settings:set("linebreak.hangAfter", hangAfter)
    end
  end
end

-- Compat: hbox building logic
local typesetter = require("typesetters.base")
if typesetter.makeHbox then
  SU.debug("silex", "No need for patching typesetter (hbox support)")
else
  SU.debug("silex", "Patching typesetter (hbox support from SILE 0.14.9)")
  if SILEVERSION >= semver("0.14.9") then
    SU.warn("SILE version "..SILE.version.." should not have needed patching hbox support")
  end

  local _rtl_pre_post = function (box, atypesetter, line)
    local advance = function () atypesetter.frame:advanceWritingDirection(box:scaledWidth(line)) end
    if atypesetter.frame:writingDirection() == "RTL" then
      advance()
      return function () end
    else
      return advance
    end
  end

  function typesetter:makeHbox (content)
    local recentContribution = {}
    local migratingNodes = {}

    local index = #(self.state.nodes)+1
    self.state.hmodeOnly = true
    SILE.process(content)
    self.state.hmodeOnly = false

    local l = SILE.length()
    local h, d = SILE.length(), SILE.length()
    for i = index, #(self.state.nodes) do
      local node = self.state.nodes[i]
      if node.is_migrating then
        migratingNodes[#migratingNodes+1] = node
      elseif node.is_unshaped then
        local shape = node:shape()
        for _, attr in ipairs(shape) do
          recentContribution[#recentContribution+1] = attr
          h = attr.height > h and attr.height or h
          d = attr.depth > d and attr.depth or d
          l = l + attr:lineContribution():absolute()
        end
      elseif node.is_discretionary then
        recentContribution[#recentContribution+1] = node
        l = l + node:replacementWidth():absolute()
        local hdisc = node:replacementHeight():absolute()
        local ddisc = node:replacementDepth():absolute()
        h = hdisc > h and hdisc or h
        d = ddisc > d and ddisc or d
      else
        recentContribution[#recentContribution+1] = node
        l = l + node:lineContribution():absolute()
        h = node.height > h and node.height or h
        d = node.depth > d and node.depth or d
      end
      self.state.nodes[i] = nil
    end

    local hbox = SILE.nodefactory.hbox({
        height = h,
        width = l,
        depth = d,
        value = recentContribution,
        outputYourself = function (box, atypesetter, line)
          local _post = _rtl_pre_post(box, atypesetter, line)
          local ox = atypesetter.frame.state.cursorX
          local oy = atypesetter.frame.state.cursorY
          SILE.outputter:setCursor(atypesetter.frame.state.cursorX, atypesetter.frame.state.cursorY)
          for _, node in ipairs(box.value) do
            node:outputYourself(atypesetter, line)
          end
          atypesetter.frame.state.cursorX = ox
          atypesetter.frame.state.cursorY = oy
          _post()
          SU.debug("hboxes", function ()
            SILE.outputter:debugHbox(box, box:scaledWidth(line))
            return "Drew debug outline around hbox"
          end)
        end
      })
    return hbox, migratingNodes
  end

  function typesetter:pushHlist (hlist)
    for _, h in ipairs(hlist) do
      self:pushHorizontal(h)
    end
  end
end

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
  -- See https://github.com/sile-typesetter/sile/issues/1718
  local oldInitLine = SILE.typesetters.base.initline
  SILE.typesetters.base.initline = function (self)
    if self.state.hmodeOnly then return end
    oldInitLine(self)
  end
else
  SU.debug("silex", "No need for patching pre-0.14.9 issues")
end
