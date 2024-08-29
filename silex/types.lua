-- Compatibility layer for SILE 0.15
if not SILE.types then
  -- Provide SILE.types to earlier versions of SILE
  SU.debug("silex", "Providing SILE.types compatibility with SILE 0.15")
  SILE.types = {
    color = SILE.color,
    length = SILE.length,
    measurement = SILE.measurement,
    node = SILE.nodefactory,
    unit = SILE.units
  }
else
  -- SILE.colorparser is now SILE.types.color in SILE 0.15, as well as SILE.color
  -- Not sure we need this for our own use cases...
  SU.debug("silex", "Silencing SILE.colorparser warning (SILE 0.15)")
  SILE.colorparser = SILE.types.color
end
