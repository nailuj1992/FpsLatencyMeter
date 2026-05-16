# Changelog

All notable changes to **FPS & Latency Meter** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.133] - 2026-05-16

### Fixed
- Crash spam `FontString:SetFont(): Arguments: ("font", fontHeight [, flags])` in `main.lua:149` when the saved `fontName` is no longer registered in LibSharedMedia (e.g., font provider addon was uninstalled or renamed). The font lookup now falls back to the LibSharedMedia default and guards against `nil` font paths in both initial setup and `UpdateFrames`.

## [0.2.132] - 2026-04-17

### Added
- Support for World of Warcraft Midnight Beta 12.0.5 via `## Interface` entry in the TOC.

## [0.2.131] - 2026-02-08

### Added
- GitHub Actions release pipeline (`release.yml`, `.pkgmeta`) for automated packaging and CurseForge deployment on tag push.

### Changed
- Color override behavior restricted to Retail only.

### Fixed
- Silent error handling on WoW client versions that do not implement Edit Mode (Classic Era, TBC, MoP), preventing taint and console errors when the Edit Mode API is unavailable.

## [0.2.131-beta] - 2026-02-08

### Changed
- Reverted the conditional gating on the date picker UI element.

## [0.2.14] - 2026-02-07

### Added
- Text input fields in the options panel to customize the on-screen content/format strings for FPS, Home MS, and World MS displays.

### Fixed
- Edit Mode disabled on Classic-line clients (MoP and earlier) where the feature has not been implemented by Blizzard.

## [0.2.13] - 2026-02-07

### Added
- Imported `LibEQOL` version 15-beta2 to provide Edit Mode shim support across client flavors.
- Initial scaffolding for customizing text content via the options panel.

## [0.2.12] - 2026-01-26

### Added
- Option to modify text alignment: `LEFT`, `CENTER`, `RIGHT` for each of the three frames.

## [0.2.11] - 2026-01-25

### Added
- Separated FPS, Home MS, and World MS into three independent, individually movable frames on both Retail and Classic.
- Options to modify font face and font size (sourced from LibSharedMedia).
- Restart/Reset button in the options panel to revert configuration to defaults.

### Changed
- Reworked options panel layout for improved readability and clearer grouping of settings.
- Classic options panel brought to parity with Retail (excluding color pickers, which remain Retail-only due to API constraints).
- Edit Mode integration restricted to Retail / Midnight clients only.

### Fixed
- Chat-related issue on MoP Classic.

### Removed
- Dead code paths tied to the removed AceGUI dependency.

## [0.2.10] - 2026-01-22

### Fixed
- Slash command registration on Midnight Beta.
- Purged unused libraries whose code attempted to access protected/secret API values on Midnight, which was producing taint errors.

## [0.2.9] - 2025-11-23

### Added
- Integrated AceGUI ColorPicker for the high/medium/low FPS and latency color settings on Midnight.

## [0.2.8] - 2025-11-22

### Added
- Compatibility with Classic Era 1.15.8, MoP Classic 5.5.2 and 5.5.3, Retail 11.2.7 (The War Within), and Midnight Beta 12.0.0 / 12.0.2.

## [0.2.7] - 2025-09-17

### Added
- TOC interface entries for MoP Classic 5.5.1 and Retail 11.2.5.

## [0.2.6] - 2025-08-05

### Added
- Support for WoW Classic Era 1.15.7.
- Support for WoW Retail 11.2.0.

## [0.2.0] - 2025-08-05

### Added
- Initial public release.
- Core addon functionality: on-screen display of current FPS, Home latency (ms), and World latency (ms).
- Configurable refresh interval, threshold-based color coding (low / medium / high), and SavedVariables persistence (`FpsLatencyMeterConfig`).
- Addon compartment entry for opening the settings panel.

[0.2.133]: https://github.com/nailuj1992/FpsLatencyMeter/compare/0.2.132...0.2.133
[0.2.132]: https://github.com/nailuj1992/FpsLatencyMeter/compare/0.2.131...0.2.132
[0.2.131]: https://github.com/nailuj1992/FpsLatencyMeter/compare/0.2.131-beta...0.2.131
[0.2.131-beta]: https://github.com/nailuj1992/FpsLatencyMeter/releases/tag/0.2.131-beta
