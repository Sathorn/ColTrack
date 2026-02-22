# Changelog

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
