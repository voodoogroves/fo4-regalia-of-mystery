# fo4-regalia-of-mystery

A Fallout 4 mod that brings the Fallout 76 Order of Mysteries gear to the Commonwealth: a Blade, a pistol, a dress, a veil and the Eye of Ra, each found broken and repaired.

**Status (2026-11-26):** one release plugin, `RegaliaOfMystery.esp`, packaged as 0.9.0 and tested in game (a few checks still open). **Published:** 0.9.1 on [Nexus Mods](https://www.nexusmods.com/fallout4/mods/111907).

## Start here

Specs and working docs are in `docs/`.

- [`docs/build-spec.md`](docs/build-spec.md): decisions, current state, how to build.
- [`docs/next-steps.md`](docs/next-steps.md): open work.
- [`docs/release-page.md`](docs/release-page.md): upload settings, page text, screenshots, last checks.
- [`docs/release-readme.txt`](docs/release-readme.txt): the readme packed into the zip.
- The other files in `docs/` are history.

`build/xedit/` holds the xEdit scripts (`BuildRegalia.pas` builds the mod), `build/art/` the texture tools, `build/package.py` makes the release zip. Game assets and built plugins are never committed.

## Licence

The scripts in `build/` are MIT ([`build/LICENSE`](build/LICENSE)). Nothing else here is openly licensed; the released mod's permissions are in its readme.

*This material is not made, guaranteed or supported by ZeniMax or its affiliates.*
