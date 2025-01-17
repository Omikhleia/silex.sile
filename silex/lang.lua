SU.debug("silex", "Patching language support for BCP47")
SILE.X = SILE.X or {}

-- A utility function to match a language against a table of entries
-- or a callback function.
-- Find the "closest" matching language by looping and removing a language
-- specifier until we get a non-nil match.
-- E.g. "xx-Xxxx-XX" will be matched against "xx-Xxxx--XX", "xx-Xxxx",
-- "xx" until one of these are satisfied.
---@param langbcp47 string                a valid BCP47 canonical language
---@param tableOrCallback table|function  a table of languages, or a callback
---@return any|nil, string|nil            a resource and the matched language
local function forLanguage(langbcp47, tableOrCallback)
  local matcher
  if type(tableOrCallback) == "table" then
    matcher = function (lang) return tableOrCallback[lang] end
  elseif type(tableOrCallback) == "function" then
    matcher = tableOrCallback
  else
    SU.error("forLanguage: second argument must be a table or a function")
  end
  while langbcp47 do
    local res = matcher(langbcp47)
    if res then
      return res, langbcp47
    end
    langbcp47 = langbcp47:match("^(.+)-.*$") -- split at dash (-) and remove last part.
  end
  return nil, nil
end
SILE.X.forLanguage = forLanguage

-- Now we can patch the language support module, hacking the initial implementation
local icu = require("justenoughicu")
SILE.scratch.loaded_languages = {}
SILE.languageSupport.languages = {}
    -- BEGIN OMIKHLEIA HACKLANG
    -- BAD CODE SMELL WARNING
    -- In earlier versions this was used where we now have a "loadonce" table of booleans.
    -- The change occurred here https://github.com/sile-typesetter/sile/commit/0c5e7f97f3c73ab1b6cd7aee0afca4a59c447cd9
    -- So this table is not handled as it was, and shouldn't be used! But:
    --   - font.lua uses it at one point...
    --   - so does languages/kn.lua
    --   - and also packages/complex-spaces
    -- END OMIKHLEIA HACKLANG

SILE.languageSupport.loadLanguage = function (language)
    language = language or SILE.settings:get("document.language")
    -- BEGIN OMIKHLEIA HACKLANG
    -- Either done too soon or plain wrong (a BCP47 language can e.g. contain
    -- a script, for instance "sr-Latn"
    -- and I don't see that in https://github.com/alerque/cldr-lua/blob/master/cldr/data/locales.lua

    -- language = cldr.locales[language] and language or "und"

    -- The user may have set document.language to anything, let's ensure a canonical
    -- BCP47 language...
    if language ~= "und" then
      language = icu.canonicalize_language(language)
    end
    -- END OMIKHLEIA HACKLANG

    if SILE.scratch.loaded_languages[language] then return end
    SILE.scratch.loaded_languages[language] = true

    -- BEGIN OMIKHLEIA HACKLANG
    -- We need to find language resources for this BCP47 identifier, from the less specific
    -- to the more general.
    local langresource, matchedlang = forLanguage(language, function (lang)
      local resource = string.format("languages.%s", lang)
      local gotres, res = pcall(require, resource)
      return gotres and res
    end)
    if not langresource then
      SU.warn(("Unable to load language feature support (e.g. hyphenation rules) for %s")
        :format(language))
    else
      SU.debug("silex", ("Loaded language feature support for %s: matched %s")
        :format(language, matchedlang))
      if language ~= matchedlang then
        -- Now that's so UGLY. Say the input language was "en-GB".
        -- It matched "en" eventually (as we don't have yet an "languages.en-GB" resources)
        -- PROBLEM: Our languages.xxx files (almost) all work by side effects, putting various things,
        -- in the case of our example, in SILE.nodeMarkers.en, SILE.hyphenator.languages.en
        -- and SU.formatNumber.en... While we now expect the language to be "en-GB"...
        -- It's a HACK, but copy the stuff into our language.
        SILE.nodeMakers[language] = SILE.nodeMakers[matchedlang]
        SU.formatNumber[language] = SU.formatNumber[matchedlang]
        SILE.hyphenator.languages[language] = SILE.hyphenator.languages[matchedlang]
      end
    end

    -- We need to find fluent reources for this BCP47 identifier, from the less specific
    -- to the more general.
    local ftlresource, resolved_resource = forLanguage(language, function (lang)
      local original_language = fluent:get_locale()
      local resource = string.format("languages.%s.messages", lang)
      fluent:set_locale(lang)
      SU.debug("fluent", "Loading FTL resource", resource, "into locale", lang)
      local gotftl, ftl = pcall(require, resource)
      if not gotftl or not ftl then
        -- Try legacy location from SILE < v0.15.7
        resource = string.format("i18n.%s", lang)
        SU.debug("fluent", "Loading FTL resource from legacy location", resource, "into locale", lang)
        gotftl, ftl = pcall(require, resource)
      end
      fluent:set_locale(original_language)
      return gotftl and ftl and resource
    end)
    if not ftlresource then
      SU.warn(("Unable to load localized strings (e.g. table of contents header text) for %s")
        :format(language))
    else
      SU.debug("silex", ("Load localized strings for %s from %s")
        :format(language, resolved_resource))
    end

    -- Most language resource files act by side effects, directly tweaking
    -- SILE.nodeMarkers.xx, SILE.hyphenator.languages.xx, SU.formatNumber.xx, etc.
    -- BUT some don't do that exactly AND return a table with an init method...
    -- Unclear API discrepancy, heh.
    if type(langresource) == "table" and langresource.init then
      langresource.init()
    end
    -- END OMIKHLEIA HACKLANG
  end
