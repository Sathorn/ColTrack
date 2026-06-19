# ColTrack

ColTrack is a World of Warcraft addon that changes minimap tracking icon colors using custom atlas presets.

It is built to make tracked node types easier to distinguish at a glance (Fish, Herb, Ore, Lumber), with profile support and quick switching from the minimap.

## Current Version
`1.0.2`

## Versioning Policy
- Patch release: increase third number (`1.0.0 -> 1.0.1`).
- Minor release: increase second number and reset third (`1.0.2 -> 1.1.0`).

## What The Addon Does
- Replaces minimap tracking icon atlas with selected preset.
- On WoW clients where Blizzard removed the required minimap texture API, ColTrack shows an in-game notice instead of silently failing.
- Supports multiple presets, including high-contrast mode.
- Supports profiles:
  - account-wide profile mode
  - per-character profile mode
- Adds a minimap button (LibDBIcon):
  - left click: next preset
  - right click: open options
- Shows graphical preset preview in addon settings.
- Includes optional Undermine vignette recolor support via a load-on-demand module.
- Undermine vignette module dependency:
  - requires `HereBeDragons` (for `HereBeDragons-Pins-2.0`)

## Presets Included
- `Base (Blizzard)`
- `Fish Pink / Herb Green / Ore Blue / Lumber Yellow`
- `Vivid: Fish Hot Pink / Herb Lime / Ore Blue / Lumber Yellow`
- `Vivid: Fish Yellow / Herb Green / Ore Blue / Lumber Pink`
- `Fish Blue / Herb Green / Ore Yellow / Lumber Pink`
- `Vivid: Fish Blue / Herb Lime / Ore Yellow / Lumber Hot Pink`
- `Deuteranomaly`
- `Deuteranopia`
- `Protanopia`
- `Tritanopia`
- `White Outline / Black Fill`

## Main Files
- `ColTrack.toc` addon metadata and load list
- `ColTrack.lua` addon logic and options UI
- `ColTrack_Vignettes/` optional Undermine vignette overlay module
- `Textures/` generated `.blp` atlas textures used by presets
- `Images/logIcon.tga` minimap button icon
- `Images/log.tga` AddOn list icon

## Install
1. Place this folder as `Interface/AddOns/ColTrack`.
2. Enable `ColTrack` in WoW AddOns.
3. Open settings: `Esc -> Options -> AddOns -> ColTrack`.
4. For Undermine vignette recolor, also install and enable `HereBeDragons`.

## Current Compatibility Note
As of WoW `12.0.7`, Blizzard has removed or hidden the minimap API ColTrack used to apply custom tracking icon atlases. ColTrack will load and show a notice, but custom minimap tracking presets cannot currently change the in-game icons on affected clients.
