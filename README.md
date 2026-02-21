# ColTrack

ColTrack is a World of Warcraft addon that changes minimap tracking icon colors using custom atlas presets.

It is built to make tracked node types easier to distinguish at a glance (Fish, Herb, Ore, Lumber), with profile support and quick switching from the minimap.

## Current Version
`0.30.2`

## Versioning Policy
- Minor release: increase third number (`0.30.0 -> 0.30.1`).
- Major release: increase second number and reset third (`0.30.x -> 0.31.0`).

## What The Addon Does
- Replaces minimap tracking icon atlas with selected preset.
- Supports multiple presets, including high-contrast mode.
- Supports profiles:
  - account-wide profile mode
  - per-character profile mode
- Adds a minimap button (LibDBIcon):
  - left click: next preset
  - right click: open options
- Shows graphical preset preview in addon settings.

## Presets Included
- `Base (Blizzard)`
- `Fish Pink / Herb Green / Ore Blue / Lumber Yellow`
- `Fish Blue / Herb Green / Ore Yellow / Lumber Pink`
- `White Outline / Black Fill`

## Main Files
- `ColTrack.toc` addon metadata and load list
- `ColTrack.lua` addon logic and options UI
- `Textures/` generated atlas textures used by presets
- `Images/logIcon.tga` minimap button icon
- `Images/log.tga` AddOn list icon

## Install
1. Place this folder as `Interface/AddOns/ColTrack`.
2. Enable `ColTrack` in WoW AddOns.
3. Open settings: `Esc -> Options -> AddOns -> ColTrack`.

## CurseForge Automatic Packaging
CurseForge packaging is configured for tagged commits.

Release steps:
1. Update version in `ColTrack.toc` and docs.
2. Commit changes to `main`.
3. Create and push a tag matching the addon version (example: `v0.30.2`).
4. CurseForge packager builds the release from the tag.

Commands:
```bash
git tag v0.30.2
git push origin main --tags
```

Packaging rules are defined in `.pkgmeta`.
