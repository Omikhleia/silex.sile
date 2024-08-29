--
-- eXperimental eXpansions to SILE
-- 2023-2024 Didier Willis
-- License: MIT
--
-- Some of these are a departure from SILE's intents.
-- Some are fixes or workarounds for issues in SILE.
--
SILE.X = SILE.X or {
  version = "0.6.0",
}
require("silex.types")
require("silex.ast")
require("silex.override")

SU.debug("silex", "Loading extra inputters if available")
pcall(function () local _ = SILE.inputters.silm end)
pcall(function () local _ = SILE.inputters.markdown end)
pcall(function () local _ = SILE.inputters.djot end)
pcall(function () local _ = SILE.inputters.pandocast end)

require("silex.fork")
require("silex.compat")
require("silex.lang")
require("silex.fixes")
