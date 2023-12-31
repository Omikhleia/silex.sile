--
-- eXperimental eXpansions to SILE
-- 2023 Didier Willis
-- License: MIT
--
-- Some of these are a departure from SILE's intents.
-- Some are fixes or workarounds for issues in SILE.
--
SILE.X = SILE.X or {
  version = "0.3.0",
}

SU.debug("silex", "Loading extra inputters if available")
pcall(function () local _ = SILE.inputters.silm end)
pcall(function () local _ = SILE.inputters.markdown end)
pcall(function () local _ = SILE.inputters.djot end)
pcall(function () local _ = SILE.inputters.pandocast end)

require("silex.fork")
require("silex.compat")
require("silex.lang")
require("silex.fixes")
