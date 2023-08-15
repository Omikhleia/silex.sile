# silex.sile

[![license](https://img.shields.io/github/license/Omikhleia/silex.sile?label=License)](LICENSE)
[![Luacheck](https://img.shields.io/github/actions/workflow/status/Omikhleia/silex.sile/luacheck.yml?branch=main&label=Luacheck&logo=Lua)](https://github.com/Omikhleia/silex.sile/actions?workflow=Luacheck)
[![Luarocks](https://img.shields.io/luarocks/v/Omikhleia/silex.sile?label=Luarocks&logo=Lua)](https://luarocks.org/modules/Omikhleia/silex.sile)

A silex is a kind of hard stone.

This is **sile·x**, a common layer for [**re·sil·ient**](https://github.com/Omikhleia/resilient.sile) and other modules:
Some common bricks and blocks, compatility features, opinionated hacks, and eXperimental eXpansions, hence the name.

:warning: **sile·x** overrides several SILE internals, and may therefore break some of your packages and classes.

## Features

**classes** and **typesetters** :warning: Opinionated departure from SILE 0.14.

Modified implementation of the base typesetter and class.

- Cancellation of the multiple package instantiation model in the base class.

  See **silex.fork** below for details.

- Propagation of hanged indent from paragraph to paragraph.

  _Rationale:_
  See [SILE discussion 1742](https://github.com/sile-typesetter/sile/discussions/1742)

**silex.lang**

This module overrides the language support in SILE to accept and resolve BCP47 language tags, such as `en-GB`, `es-MX`, `fr-CH`, etc.
In other layman's terms, it changes the behavior of SILE's `\language` command.
This implementation does _not_ change how SILE's `\font[language=...]` command works.

_Rationale:_
See [SILE PR 1641](https://github.com/sile-typesetter/sile/pull/1641) for details and more complete proposal.
We cannot wait forever for SILE to implement this: Markdown and Djot need to be able to support qualified language names, notably for smart quotes to work adequately.

**silex.fixes** :warning: Opinionated departure from SILE 0.14.

This modules implements some additions and changes which should be provided by SILE in my humble opinion...

- More tolerance on uninitialized inputters options (non-breaking)

- Greek numbering ("greek") for counters, similar to the existing "alpha" (non-breaking)

  _Rationale:_
  There are books where one wants to "number" items with Greek letters in sequence (e.g. annotations in biblical material), as α β γ δ ε ζ η θ ι κ λ μ ν ξ ο π ρ σ τ υ φ χ ψ ω. ICU provides _arithmetic_ Greek numbering systems, but this is not what one wants here.

- Re-implementation of the centered and ragged environments, to respect margins (a.k.a. left and right skips) when nested (for instance in block quotes) and to honor the paragraph indent (possibly breaking :warning:)
  
  _Rationale:_
  The "core" implementation of these environments is broken since its inception.

- Re-implementation of the `\em` command to support nested emphasis (possibly breaking :warning:)

  _Rationale:_
  See [SILE issue 1048](https://github.com/sile-typesetter/sile/issues/1048) for context. Djot and Markdown both recognize nested emphasis...

**silex.fork** :warning: Opinionated departure from SILE 0.14.

The module cancels the multiple package instantiation model introduced in SILE 0.13-0.14. Packages are no longer re-instantiated when loaded multiple times.

_Rationale:_
I struggled too many times with this issue in August 2021 (initial effort porting my 0.12.5 packages to 0.14.x) and afterwards.
See [SILE issue 1531](https://github.com/sile-typesetter/sile/issues/1531) for some details.
I can't make _any_ sense of this half-baked "feature", which introduces unintended side-effects and problems impossible to decently address, making the life of package and class developers real harder. So I'm moving on and cancelling it.
The _very few_ cases where this could have been interesting can be addressed in other ways...

**silex.ast**

A library of common SILE AST utilities.

_Rationale:_
The need for such functions kept popping up in my packages and inputters, so I decided to factor them out, to ease maintenance and avoid code duplication.
In my humble opinion, SILE should eventually provide these functions in the core distribution (and clean up or refactor some of its existing methods on that occasion)...

**silex.compat**

Compatibility layer providing some fixes also proposed to SILE and possibly integrated in a release.
This is obviously not exhaustive, and it only covers issues I backported for my own packages to work with the then-current SILE releases.

_Rationale:_
Official release dates are not predictable, and may moreover take some time to reach the users, but normally you do not need to use this module if you are using the latest SILE release.

## Affected modules

If you use packages or classes from the following modules, some features of **silex** will be loaded globally. Your documents using them may therefore be impacted from that point on.

- The packages from [smartquotes.sile](https://github.com/Omikhleia/smartquotes.sile) enable **silex.lang**.

- The packages and inputters from [markdown.sile](https://github.com/Omikhleia/markdown.sile) enable **silex.lang**.

- The packages from [ptable.sile](https://github.com/Omikhleia/ptable.sile) enable **silex.compat**.

- The packages and classes from [resilient.sile](https://github.com/Omikhleia/resilient.sile) enable **all** features.

## Future directions

The plan: SILE + **sile·x** + **re·sil·ient** = SILE as it should be.

Did I say this was opinionated?
Whatever you may think, expect some more breaking changes and furious experiments in the future...

## License

All code is under the MIT License.
