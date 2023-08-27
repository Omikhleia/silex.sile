local base = require("outputters.base")
SILE.shaper = SILE.shapers.harfbuzz()

local cursorX = 0
local cursorY = 0

local started = false
local lastkey = false

local debugfont = SILE.font.loadDefaults({ family = "Gentium Plus", language = "en", size = 10 })

local _dl = 0.5

local _debugfont
local _font

-- local function _round (input)
--   -- LuaJIT 2.1 betas (and inheritors such as OpenResty and Moonjit) are biased
--   -- towards rounding 0.5 up to 1, all other Lua interpreters are biased
--   -- towards rounding such floating point numbers down.  This hack shaves off
--   -- just enough to fix the bias so our test suite works across interpreters.
--   -- Note that even a true rounding function here will fail because the bias is
--   -- inherent to the floating point type. Also note we are erroring in favor of
--   -- the *less* common option beacuse the LuaJIT VMS are hopelessly broken
--   -- whereas normal LUA VMs can be cooerced.
--   if input > 0 then input = input + .00000000000001 end
--   if input < 0 then input = input - .00000000000001 end
--   return string.format("%.4f", input)
-- end

local outputter = pl.class(base)
outputter._name = "html"
outputter.extension = "html"

-- N.B. Sometimes setCoord is called before the outputter has ensured initialization.
-- This ok for coordinates manipulation, at these points we know the page size.
local deltaX
local deltaY
local function trueXCoord (x)
  if not deltaX then
    deltaX = (SILE.documentState.sheetSize[1] - SILE.documentState.paperSize[1]) / 2
  end
  return x + deltaX
end
local function trueYCoord (y)
  if not deltaY then
    deltaY = (SILE.documentState.sheetSize[2] - SILE.documentState.paperSize[2]) / 2
  end
  return y + deltaY
end

-- The outputter init can't actually initialize output (as logical as it might
-- have seemed) because that requires a page size which we don't know yet.
-- function outputter:_init () end

local _div = {}
local _fname
function outputter:_ensureInit ()
  if not started then
    local w, h = SILE.documentState.sheetSize[1], SILE.documentState.sheetSize[2]
    local fname = self:getOutputFilename()
    _fname = fname
    -- Ideally we could want to set the PDF CropBox, BleedBox, TrimBox...
    -- Our wrapper only manages the MediaBox at this point.
    --pdf.init(fname == "-" and "/dev/stdout" or fname, w, h, SILE.full_version)
    print("Writing HTML to " .. fname)
    local fd, err = io.open(fname == "-" and "/dev/stdout" or fname, "w")
    if not fd then return SU.error(err) end
    self.fd = fd
    self.fd:write(table.concat({
      "<!DOCTYPE html>",
      "<html>",
      "<head>",
      "<meta charset=\"utf-8\">",
      "<title>" .. "XXXX" .. "</title>",
      "<style>",
      "body {",
      "}",
      ".page {",
      "  position: relative;",
      "  width: " .. w .. "pt;",
      "  height: " .. h .. "pt;",
      "  border: 1px solid gray;",
      "  margin: 5pt;",
      "  box-shadow: 3pt 3pt lightgray;",
      "  display: inline-block;",
      "}",
      "span {",
      "  border: 0.1pt solid purple;",
      "}",
      "</style>",
      "</head>",
      "<body>",
      "<div class=\"page\">",

    }, "\n"))
    _div[#_div+1] = { x = 0, y = 0, w = w, h = h }
    started = true
  end
end

function outputter:newPage ()
  self:_ensureInit()
  self.fd:write('</div>\n')
  self.fd:write("<div class=\"page\">")
end

-- pdf stucture package needs a tie in here
function outputter._endHook (_)
  -- FIXME: NOT IMPLEMENTED
end

function outputter:finish ()
  self:_ensureInit()
  self.fd:write("</div>\n")
  self:_endHook()
  self.fd:write("</body></html>\n")
  self.fd:close()
  started = false
  lastkey = nil
end

function outputter.getCursor (_)
  return cursorX, cursorY
end

function outputter.setCursor (_, x, y, relative)
  x = SU.cast("number", x)
  y = SU.cast("number", y)
  local offset = relative and { x = cursorX, y = cursorY } or { x = 0, y = 0 }
  cursorX = offset.x + x
  cursorY = offset.y + (relative and 0 or SILE.documentState.paperSize[2]) - y
end

-- FIXME not called from the 0.14 code base!!!
function outputter:setColor (_)
  self:_ensureInit()
  SU.error("setColor not implemented")
end

local cssColorStack = { "rgb(0,0,0)" }
local function cmykToRgb(c, m, y, k)
  local r = 255 * (1 - c) * (1 - k)
  local g = 255 * (1 - m) * (1 - k)
  local b = 255 * (1 - y) * (1 - k)
  return r, g, b
end

function outputter:pushColor (color)
  self:_ensureInit()
  if color.r then
    cssColorStack[#cssColorStack+1] = "rgb(" .. color.r * 255 .. ", " .. color.g * 255 .. ", " .. color.b * 255 .. ")"
  elseif color.c then
    local r, g, b = cmykToRgb(color.c, color.m, color.y, color.k)
    cssColorStack[#cssColorStack+1] = "rgb(" .. r .. ", " .. g .. ", " .. b .. ")"
  elseif color.l then
    cssColorStack[#cssColorStack+1] = "rgb(" .. color.l  * 255 .. ", " .. color.l * 255 .. ", " .. color.l * 255 .. ")"
  end
end

function outputter:popColor ()
  self:_ensureInit()
  cssColorStack[#cssColorStack] = nil
end

function outputter:_drawString (str, width, x_offset, y_offset)
  local x, y = self:getCursor()

  x = x - _div[#_div].x
  y = y - _div[#_div].y
  local xt = trueXCoord(x+x_offset)
  local yt = trueYCoord(y+y_offset)
  self.fd:write('<div style="position:absolute;'
    .. 'left:' .. xt .. 'pt;'
    .. 'bottom:' .. yt .. 'pt;'
    .. ' width:' .. width .. 'pt;'
    .. 'height:' .. _font.metrics.ascender .. 'pt;'
    .. _font.css
    .. '; color:' .. cssColorStack[#cssColorStack] .. ';'
    ..'">'
    .. str
    ..'</div>')
end

function outputter:drawHbox (value, width)
  width = SU.cast("number", width)
  self:_ensureInit()
  if not value.glyphString then return end
  -- Nodes which require kerning or have offsets to the glyph
  -- position should be output a glyph at a time. We pass the
  -- glyph advance from the htmx table, so that libtexpdf knows
  -- how wide each glyph is. It uses this to then compute the
  -- relative position between the pen after the glyph has been
  -- painted (cursorX + glyphAdvance) and the next painting
  -- position (cursorX + width - remember that the box's "width"
  -- is actually the shaped x_advance).
  if value.complex then
    for i = 1, #value.items do
      local item = value.items[i]
      self:_drawString(item.text, item.glyphAdvance, item.x_offset or 0, item.y_offset or 0)
      self:setCursor(item.width, 0, true)
    end
  else
    self:_drawString(value.text, width, 0, 0)
    self:setCursor(width, 0, true)
  end
end

function outputter:_withDebugFont (callback)
  if not _debugfont then
    _debugfont = self:setFont(debugfont)
  end
  local oldfont = _font
  _font = _debugfont
  callback()
  _font = oldfont
end

local function featuresToCss(features)
  local css = ""
  for feature in features:gmatch("([%+%-%w]+)") do
    local state = "on"
    local featureName = feature
    if feature:sub(1, 1) == "+" then
      featureName = feature:sub(2)
    elseif feature:sub(1, 1) == "-" then
      featureName = feature:sub(2)
      state = "off"
    end
    css = css .. string.format("font-feature-settings: '%s' %s;", featureName, state)
  end
  return css
end

local function fontToCss(font)
  local props = {
    "font-family: " .. font.family,
    "font-size: " .. font.size .. "pt",
    "font-weight: " .. font.weight,
  }
  if font.style and font.style:lower() == "italic" then
    props[#props + 1] = "font-style: italic"
  else
    props[#props + 1] = "font-style: normal"
  end
  local css = table.concat(props, ";")
  if font.features then
    css = css .. ";" .. featuresToCss(font.features)
  end
  return css
end

function outputter:setFont (options)
  self:_ensureInit()
  local key = SILE.font._key(options)
  if lastkey and key == lastkey then return _font end
  -- FIXME handle direction?
  -- local font = SILE.font.cache(options, SILE.shaper.getFace)
  -- if options.direction == "TTB" then
  --   ???
  -- end
  -- if SILE.typesetter.frame and SILE.typesetter.frame:writingDirection() == "TTB" then
  --   ???
  -- else
  --  ???
  -- end
  local metrics = require("fontmetrics")
  local face = SILE.font.cache(options, SILE.shaper.getFace)
  local m = metrics.get_typographic_extents(face)
  m.ascender = m.ascender * options.size
  m.descender = m.descender * options.size
  _font = {
    css = fontToCss(options),
    spec = options,
    metrics = m
  }
  lastkey = key
  return _font
end

function outputter:drawImage (src, x, y, width, height, _)
  x = SU.cast("number", x)
  y = SU.cast("number", y)
  width = SU.cast("number", width)
  height = SU.cast("number", height)
  x = trueXCoord(x)
  y = trueYCoord(y)

  -- FIXME use bottom instead of top?
  x = x - _div[#_div].x
  y = y - _div[#_div].y
  -- FIXME RELATIVE PATH HACK
  -- FIXME escapes needed in the regex!
  local dir = pl.path.dirname(_fname)
  src = src:gsub("^"..dir.."/", ""):gsub("^/"..dir.."/", "")
  self:_ensureInit()
  self.fd:write('<div style="position:absolute; left:' .. x .. 'pt; top:' .. y .. 'pt; width:' .. width .. 'pt; height:' .. height .. 'pt;">')
  self.fd:write("<img src=\"" ..src .. "\" width=\"100%\" height=\"100%\" />")
  self.fd:write("</div>")
end

function outputter.getImageSize (_, src, pageno)
  local pdf = require("justenoughlibtexpdf")
  local llx, lly, urx, ury, xresol, yresol = pdf.imagebbox(src, pageno or 1)
  return (urx-llx), (ury-lly), xresol, yresol
end

local function pathToSVG(path) -- FIXME broken, needs to be rewritten
  local svgPath = ""
  local i = 1
  local _, ep, operands
  while i < #path do
    _, ep, operands = path:find("(%g+%s+%g+)%s+m%s+", i)
    if operands then
      svgPath = svgPath .. "M" .. operands .. " "
      i = ep + 1
    else
      _, ep, operands = path:find("(%g+%s+%g+%s+%g+%s+%g+%s+%g+%s+%g+)%s+c%s+", i)
      if operands then
        svgPath = svgPath .. "C" .. operands .. " "
        i = ep + 1
      else
        break
      end
    end
  end
  if svgPath == "" then
    SU.warn("Invalid path: " .. path)
  end
  return svgPath .. "Z"
end


function outputter:drawSVG (figure, x, y, width, height, scalefactor)
  self:_ensureInit()

  local d = pathToSVG(figure)

  x = SU.cast("number", x)
  y = SU.cast("number", y)
  height = SU.cast("number", height)
  width = SU.cast("number", width)

  self:setCursor(x, y)
  x, y = self:getCursor()

  x = x - _div[#_div].x
  y = y - _div[#_div].y

  x = trueXCoord(x)
  y = trueYCoord(y)

  self.fd:write('<div style="position:absolute; left:' .. x .. 'pt; bottom:' .. y .. 'pt; width:' .. width .. 'pt; height:' .. height .. 'pt;">')
  self.fd:write('<svg style="position:inherit;" width="' .. width .. 'pt" height="' .. height .. 'pt" viewBox="0 0 ' .. width / scalefactor .. ' ' .. height / scalefactor .. '" xmlns="http://www.w3.org/2000/svg">')
  self.fd:write('<path d="' .. d .. '"/>')
  self.fd:write('</svg>')
  self.fd:write("</div>")
end

function outputter:drawRule (x, y, width, height)
  x = SU.cast("number", x)
  y = SU.cast("number", y)
  width = SU.cast("number", width)
  height = SU.cast("number", height)
  self:_ensureInit()
  x = trueXCoord(x)
  y = trueYCoord(y)

  -- FIXME: Logic is wrong here
  local paperY = SILE.documentState.sheetSize[2]
  if not _div[#_div].rel then
    y = paperY - y - height
  else
    y = paperY - y - height
    x = x - _div[#_div].x
    y = y - _div[#_div].y
  end
  if width < 0 then
    x = x + width
    width = -width
  end
  if height < 0 then
    y = y + height
    height = -height
  end
  self.fd:write("<div style=\"position:absolute;"
   .." left:" .. x .. "pt; bottom:" .. y .. "pt; width:"
      .. width .. "pt; height:" .. height .. "pt;"
  .. " background: " .. cssColorStack[#cssColorStack]
  .. "\">")
  self.fd:write('</div>')
end

function outputter:debugFrame (frame)
  self:_ensureInit()
  self:pushColor({ r = 0.8, g = 0, b = 0 })
  self:drawRule(frame:left()-_dl/2, frame:top()-_dl/2, frame:width()+_dl, _dl)
  self:drawRule(frame:left()-_dl/2, frame:top()-_dl/2, _dl, frame:height()+_dl)
  self:drawRule(frame:right()-_dl/2, frame:top()-_dl/2, _dl, frame:height()+_dl)
  self:drawRule(frame:left()-_dl/2, frame:bottom()-_dl/2, frame:width()+_dl, _dl)
  -- FIXME NOT IMPLEMENTED
  -- local stuff = SILE.shaper:createNnodes(frame.id, debugfont)
  -- stuff = stuff[1].nodes[1].value.glyphString -- Horrible hack
  -- local buf = {}
  -- for i = 1, #stuff do
  --   buf[i] = glyph2string(stuff[i])
  -- end
  -- buf = table.concat(buf, "")
  -- self:_withDebugFont(function ()
  --   self:setCursor(frame:left():tonumber() - _dl/2, frame:top():tonumber() + _dl/2)
  --   self:_drawString(buf, 0, 0, 0)
  -- end)
  self:popColor()
end

function outputter:debugHbox (hbox, scaledWidth)
  self:_ensureInit()
  self:pushColor({ r = 0.8, g = 0.3, b = 0.3 })
  local paperY = SILE.documentState.paperSize[2]
  local x, y = self:getCursor()
  y = paperY - y
  self:drawRule(x-_dl/2, y-_dl/2-hbox.height, scaledWidth+_dl, _dl)
  self:drawRule(x-_dl/2, y-hbox.height-_dl/2, _dl, hbox.height+hbox.depth+_dl)
  self:drawRule(x-_dl/2, y-_dl/2, scaledWidth+_dl, _dl)
  self:drawRule(x+scaledWidth-_dl/2, y-hbox.height-_dl/2, _dl, hbox.height+hbox.depth+_dl)
  if hbox.depth > SILE.length(0) then
    self:drawRule(x-_dl/2, y+hbox.depth-_dl/2, scaledWidth+_dl, _dl)
  end
  self:popColor()
end

-- The methods below are only implemented on outputters supporting these features.
-- In PDF, it relies on transformation matrices, but other backends may call
-- for a different strategy.
-- ! The API is unstable and subject to change. !

function outputter:scaleFn (xorigin, yorigin, xratio, yratio, callback)
  xorigin = SU.cast("number", xorigin)
  yorigin = SU.cast("number", yorigin)
  local paperY = SILE.documentState.sheetSize[2]
  local x0 = trueXCoord(xorigin)
  local y0 = paperY - trueYCoord(yorigin)
  self:_ensureInit()

  local xt = x0 - _div[#_div].x
  local yt = y0 - _div[#_div].y

  _div[#_div+1] = { x = x0, y = y0, rel = true }

  local style = {
    position = "absolute",
    left = xt .. "pt",
    bottom = yt .. "pt",
    transform = "scale(" .. xratio .. ", " .. yratio .. ")"
  }
  local s = ""
  for k, v in pairs(style) do
    s = s .. k .. ":" .. v .. ";"
  end

  self.fd:write('<div style="' .. s .. ';">')
  callback()
  self.fd:write("</div>")

  _div[#_div] = nil
end

function outputter:rotateFn (xorigin, yorigin, theta, callback)
  xorigin = SU.cast("number", xorigin)
  yorigin = SU.cast("number", yorigin)
  local paperY = SILE.documentState.sheetSize[2]
  local x0 = trueXCoord(xorigin)
  local y0 = paperY - trueYCoord(yorigin)
  self:_ensureInit()

  local xt = x0 - _div[#_div].x
  local yt = y0 - _div[#_div].y

  _div[#_div+1] = { x = x0, y = y0, rel = true }

  local style = {
    position = "absolute",
    left = xt .. "pt",
    bottom = yt  .. "pt", --
    transform = "rotate(" .. -theta .. "rad)"
  }
  local s = ""
  for k, v in pairs(style) do
    s = s .. k .. ":" .. v .. ";"
  end

  self.fd:write('<div style="' .. s .. ';">')
  callback()
  self.fd:write("</div>")

  _div[#_div] = nil
end

-- Unstable link APIs

function outputter:linkAnchor (x, y, name)
  x = SU.cast("number", x)
  y = SU.cast("number", y)
  self:_ensureInit()
  local x0 = trueXCoord(x)
  local y0 = trueYCoord(y)
  self:_ensureInit()

  local xt = x0 - _div[#_div].x
  local yt = y0 - _div[#_div].y

  local style = {
    position = "absolute",
    left = xt .. "pt",
    bottom = yt .. "pt",
  }
  local s = ""
  for k, v in pairs(style) do
    s = s .. k .. ":" .. v .. ";"
  end

  self.fd:write('<div id="'..name..'" style="' .. s .. ';"></div>')
end

function outputter:enterLinkTarget (x0, y0, dest, options)
  local target = options.external and dest or ("#" .. dest)

  x0 = trueXCoord(x0)
  y0 = trueYCoord(y0)
  self:_ensureInit()

  local xt = x0 - _div[#_div].x
  local yt = y0 - _div[#_div].y

  _div[#_div+1] = { x = x0, y = y0, rel = true }

  local style = {
    position = "absolute",
    left = xt .. "pt",
    bottom = yt .. "pt",
  }
  local s = ""
  for k, v in pairs(style) do
    s = s .. k .. ":" .. v .. ";"
  end

  self.fd:write('<div style="' .. s .. ';">'
   .. '<a href="' .. target .. '">')
end
function outputter:leaveLinkTarget (_, _, _, _, _, _)
  self.fd:write("</a></div>")
  _div[#_div] = nil
end

-- Bookmarks and metadata

local function validate_date (date)
  return string.match(date, [[^D:%d+%s*-%s*%d%d%s*'%s*%d%d%s*'?$]]) ~= nil
end

function outputter:setMetadata (key, value)
  if key == "Trapped" then
    SU.warn("Skipping special metadata key \\Trapped")
    return
  end

  if key == "ModDate" or key == "CreationDate" then
    if not validate_date(value) then
      SU.warn("Invalid date: " .. value)
      return
    end
  end
  self:_ensureInit()
  -- FIXME: NOT IMPLEMENTED
end

function outputter:setBookmark (_, _, _) -- dest, title, level
  self:_ensureInit()
  -- FIXME: NOT IMPLEMENTED
end

return outputter
