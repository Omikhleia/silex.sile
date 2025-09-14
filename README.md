# silex.sile

[![license](https://img.shields.io/github/license/Omikhleia/silex.sile?label=License)](LICENSE)
[![Luacheck](https://img.shields.io/github/actions/workflow/status/Omikhleia/silex.sile/luacheck.yml?branch=main&label=Luacheck&logo=Lua)](https://github.com/Omikhleia/silex.sile/actions?workflow=Luacheck)

> [!IMPORTANT]
> Parts of module are now provided directly in [resilient.sile](https://github.com/Omikhleia/resilient.sile) collection (release v3.2.0)
> when they aren't available in SILE 0.15 or upper.
> 
> The **sile·x** module served us well for several years, providing at the same time compatibility layers, advanced new features, early-adopted features,
> and a ground where to experiment new ideas. It has achieved that role beyond expectations, but it's more than time to retire it.
> 
> This repository is no longer maintained and will be archived.

A silex is a kind of hard stone.

This ~~is~~ was **sile·x**, a common layer for [**re·sil·ient**](https://github.com/Omikhleia/resilient.sile) and other modules:
Some common bricks and blocks, compatility features, opinionated hacks, and eXperimental eXpansions, hence the name.

:warning: The **sile·x** components overrode several SILE internals when fully enabled, and could therefore break some of your packages and classes.

### Removal

Uninstall:

```shell
luarocks remove silex.sile
```
## Features (not exhaustive)

**classes** and **typesetters**

Modified implementation of the base typesetter and class.

- Cancellation of the multiple package instantiation model in the base class.

  See **silex.fork** below for details.

  This feature is now an integral part of **resilient.sile** v3.0.0 ✔️

- Propagation of hanged indent from paragraph to paragraph.

  _Rationale:_
  See [SILE discussion 1742](https://github.com/sile-typesetter/sile/discussions/1742)

  This feature is now an integral part of **resilient.sile** v3.0.0 ✔️

- Multi-liners i.e. support for environment spanning multiple lines.

  _Rationale:_
  Early adoption of SILE PR [1977](https://github.com/sile-typesetter/sile/pull/1977)

  This feature is now available in SILE 0.15 ✔️ 

**outputters and packages**

Modified implementation of the PDF outputter and of several packages depending on it.

_Rationale:_
Early adoption of SILE PR [1853](https://github.com/sile-typesetter/sile/pull/1853)

The corresponding changes were made available in SILE 0.15 ✔️

**silex.lang**

This module overrides the language support in SILE to accept and resolve BCP47 language tags, such as `en-GB`, `es-MX`, `fr-CH`, etc.
In other layman's terms, it changes the behavior of SILE's `\language` command.
This implementation does _not_ change how SILE's `\font[language=...]` command works.

_Rationale:_
See [SILE PR 1641](https://github.com/sile-typesetter/sile/pull/1641) for details and more complete proposal.
We cannot wait forever for SILE to implement this: Markdown and Djot need to be able to support qualified language names, notably for smart quotes to work adequately.

While still an open issue in SILE 0.15.13, this feature is now an integral part of **resilient.sile** v3.2.0 ✔️

**silex.fixes**

This modules implements some additions and changes which were proposed for inclusion in SILE.

- More tolerance on uninitialized inputters options (non-breaking)

  This fix is now available in SILE 0.15 ✔️

- Greek numbering ("greek") for counters, similar to the existing "alpha" (non-breaking)

  _Rationale:_
  There are books where one wants to "number" items with Greek letters in sequence (e.g. annotations in biblical material), as α β γ δ ε ζ η θ ι κ λ μ ν ξ ο π ρ σ τ υ φ χ ψ ω. ICU provides _arithmetic_ Greek numbering systems, but this is not what one wants here.

  This utility is now available in SILE 0.15 ✔️

- Re-implementation of the centered and ragged environments, to respect margins (a.k.a. left and right skips) when nested (for instance in block quotes) and to honor the paragraph indent.
  
  _Rationale:_
  The "core" implementation of these environments was broken since its inception.

  These features are now available in SILE 0.15 ✔️

- Re-implementation of the `\em` command to support nested emphasis

  _Rationale:_
  See [SILE issue 1048](https://github.com/sile-typesetter/sile/issues/1048) for context. Djot and Markdown both recognize nested emphasis...

  This feature is bow available in SILE 0.15 ✔️

**silex.fork**

The module cancels the multiple package instantiation model introduced in SILE 0.13-0.14. Packages are no longer re-instantiated when loaded multiple times.

This feature (a departure from SILE's default behavior) is now an integral part of **resilient.sile** v3.0.0 ✔️

**silex.ast**

A library of common SILE AST utilities.

_Rationale:_
The need for such functions kept popping up in my packages and inputters, so I decided to factor them out, to ease maintenance and avoid code duplication.
In my humble opinion, SILE should eventually provide these functions in the core distribution (and clean up or refactor some of its existing methods on that occasion)...

These utilities are now available in SILE 0.15 ✔️

**silex.compat**

Compatibility layer providing some fixes also proposed to SILE and possibly integrated in a release (0.14-0.15)
This is obviously not exhaustive, and it only covers issues I backported for my own packages to work with the then-current SILE releases.

This old compatibility layer was hard to maintain, and we do not plan to support older versions of SILE any longer.
Everything should now be fine with SILE 0.15 and **resilient.sile** v3.x ✔️

**silex.override**

When loaded, this layer enforces using silex-modified versions of some packages and components, overriding the original ones.

This feature obviously makes no sense with the deprecation of this module ✔️

## License

All code is under the MIT License.
