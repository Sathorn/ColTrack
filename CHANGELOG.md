# Changelog

## v0.30.5-beta5
- Added optional Undermine vignette recolor support using a load-on-demand module (`ColTrack_Vignettes`).
- Added auto-load behavior for the vignette module when enabled and entering Undermine.
- Added separate settings tabs and ordering updates:
  - `Tracking Presets`
  - `Minimap Options`
  - `Undermine Vignettes`
  - `Profiles` (kept last)
- Added configurable colors for Undermine vignette groups:
  - `Shiny Trash Can`
  - `Overflowing Dumpster`
  - `One-time Treasures`
- Added legacy preset ID normalization and minimap texture reapply hardening on world/tracking updates.
- Replaced vivid blue preset variant with:
  - `Vivid: Fish Blue / Herb Lime / Ore Yellow / Lumber Hot Pink`

## v0.30.5-beta4
- Replaced `Vivid: Fish Blue / Herb Green / Ore Yellow / Lumber Pink` with:
  - `Vivid: Fish Blue / Herb Lime / Ore Yellow / Lumber Hot Pink`
  - Fish `#0091FF`, Herb `#35FF00`, Ore `#FDFF00`, Lumber `#FF00A0`
- Updated Presets tab cosmetics:
  - renamed title to `Presets Preview`
  - removed separate `Preview` label
  - split rows into `Standard Presets` and `Accessibility Presets`
- Added saved preset migration for legacy texture IDs so old profiles map to current presets.
- Added minimap blip texture reapply on world/tracking updates to reduce reset mismatches.
- Updated version references in TOC/README/docs.

## v0.30.5-beta3
- Replaced generic colorblind presets with type-specific presets:
  - `Deuteranomaly`
  - `Deuteranopia`
  - `Protanopia`
  - `Tritanopia`
- Tuned per-type palettes for better in-game readability and clearer contrast.
- Regenerated colorblind atlas textures as `.blp` with no mipmaps to avoid minimap artifacting.
- Removed old colorblind atlas files (`ObjectIconsAtlas_colorblindRG.blp`, `ObjectIconsAtlas_colorblindBY.blp`).
- Updated README/docs preset lists and version references.

## v0.30.5-beta2
- Switched preset atlas textures from `.tga` to `.blp` (BLP2/DXT5) for smaller download size.
- Removed legacy `.tga` atlas files from `Textures/`.
- Kept all preset names and color variants unchanged.

## v0.30.5-beta1
- Added two new bright preset families:
  - `Vivid: Fish Magenta / Herb Lime / Ore Cyan / Lumber Gold`
  - `Vivid: Fish Blue / Herb Green / Ore Yellow / Lumber Pink`
- Added two accessibility presets targeted for common color-vision deficiencies:
  - `Colorblind (Red-Green Safe)`
  - `Colorblind (Blue-Yellow Safe)`
- Reworked vivid/colorblind texture generation to preserve Blizzard-style dark outlines.
- Removed redundant preset dropdown from the Presets tab (single click-list selector remains).
- Improved Presets preview layout:
  - fixed long-label overlap with icon previews
  - aligned icon column placement
- Reordered presets for clearer flow:
  - base -> standard/vivid pair 1 -> standard/vivid pair 2 -> colorblind presets -> white/black preset.
- Updated `README.md` and `docs/index.html` to match the new preset lineup and palette values.

## v0.30.4
- Bumped addon version to 0.30.4.
- Updated documentation version references.

## v0.30.3
- Cleaned repository for tag-based release flow.
- Removed non-essential tracked assets and duplicate Pages workflow.

## v0.30.2
- Updated author metadata to `Sathorn`.
- Switched minimap icon to `Images/logIcon.tga`.
- Added AddOn List icon metadata.
