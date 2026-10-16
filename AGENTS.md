# AGENTS.md — FPS & Latency Meter

Guidance for AI coding agents working in this repository.

## Project

World of Warcraft addon that shows the client's FPS and Home/World latency on screen, with a settings panel to toggle, position, colour and restyle each indicator.

- **Author / maintainer:** Nailuj1992
- **CurseForge:** https://www.curseforge.com/wow/addons/fps-latency-meter (project ID `1321145`)
- **Language:** Lua 5.1 (WoW UI environment), plus TOC and XML

### Supported clients

One TOC serves every client through a comma-separated `## Interface` list.

| Client | Version | Interface |
|---|---|---|
| Retail (Midnight) | 12.1.5 | `120105` |
| MoP Classic | 5.5.4 | `50504` |
| TBC Classic Anniversary | 2.5.6 | `20506` |
| Classic Era | 1.15.9 | `11509` |
| WoW Forever (beta) | 1.60.1 | `16001` |

WoW Forever reports a `1.x` build, so it can't be detected by major version alone. Use `WOW_PROJECT_ID == WOW_PROJECT_CAMELOT` or an interface number between 16000 and 19999.

## Layout

| File | Purpose |
|---|---|
| `FpsLatencyMeter.toc` | Metadata, interface list, load order |
| `embeds.xml` | Loads the embedded libraries |
| `options.lua` | Defaults, SavedVariables (`FpsLatencyMeterConfig`), settings panel, slash commands (`/fps`, `/latency`, `/ms`) |
| `main.lua` | On-screen frame, `OnUpdate` refresh, colouring |
| `Libs/` | Third-party libraries. **Not tracked in git.** |
| `.pkgmeta` | BigWigs packager config (externals, ignore list, changelog) |
| `.github/workflows/release.yml` | Builds and uploads to CurseForge when a tag is pushed |

Libraries: LibStub, CallbackHandler-1.0, LibSharedMedia-3.0, LibChangelog, UTF8 (from `.pkgmeta` externals) and LibEQOL (installed by the workflow).

## Guidelines

- **Cross-client APIs:** every API must exist on all five clients, or be guarded. Use the existing pattern: `local X = C_Namespace and C_Namespace.X or X`.
- **No new globals.** The only intended globals are the addon table (`_G[addOnName]`), `FpsLatencyMeterConfig`, `OpenFpsLatencySettings` (used by `AddonCompartmentFunc`) and the slash-command entries.
- **Retail-only features** go behind `TT:IsRetail()`. Colour pickers are one such feature today.
- **Settings** go through `LibEQOLSettingsMode-1.0`, following the existing `CreateParentedSlider` / `CreateParentedScrollDown` helpers.
- **Saved variables:** add new keys to `FpsLatencyMeterBaseConfig`. Never rename or remove existing keys without migrating them, because users' saved settings would be lost.
- **Fonts:** always resolve them through LibSharedMedia, with a fallback to `LSM:GetDefault`. Never call `SetFont` with a nil path.
- **Line endings:** `.lua` files use CRLF. Keep them that way.
- **Style:** 4-space indentation, `local` everything, match the surrounding code.

### Releases

- Bump `## Version` in the TOC and add a `CHANGELOG.md` entry together, using [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.
- When a client patch ships, update the `## Interface` list and drop numbers for patches that are no longer live.
- Commit messages follow Conventional Commits (`feat:`, `fix:`, `docs:` …).

## Restrictions

- **Never push git tags.** Any tag push triggers `release.yml` and publishes to CurseForge. Releasing is the maintainer's decision.
- **Never push to `master` directly.** Work on a branch and open a pull request.
- **Never commit `Libs/`.** It is git-ignored and filled at build time by the packager. Don't edit library code to fix addon bugs; fix it in the addon.
- **Don't change `.github/workflows/` or `.pkgmeta`** unless asked. Never print, log or commit secrets (`CURSE_API_TOKEN`).
- **Don't touch the user's WoW installation** (`World of Warcraft\_*_\Interface\AddOns`, `WTF`/SavedVariables) unless explicitly asked. Back files up before overwriting them.
- **Changes can't be run here.** No WoW client or Lua runtime is available. Say clearly that in-game testing is still needed; don't claim a change "works".
- **Avoid taint.** Don't modify Blizzard secure frames, and don't call protected functions in combat. Hook with `hooksecurefunc`, not by replacing Blizzard functions.
