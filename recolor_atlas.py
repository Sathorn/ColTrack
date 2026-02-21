from pathlib import Path
from collections import deque
from PIL import Image

SRC = Path("/home/sath/projects/ColTrack/Images/objecticonsatlas.png")
OUT_DIR = Path("/home/sath/projects/ColTrack/Textures")

# icon rectangles: (x, y, w, h)
RECTS = {
    "fish": (928, 517, 32, 32),
    "herb": (963, 520, 32, 32),
    "ore": (520, 554, 32, 32),
    "lumber": (928, 453, 32, 32),
}

PRESETS = [
    (
        "ObjectIconsAtlas_fishPink_herbGreen_oreBlue_lumberYellow.tga",
        {
            "fish": "#FF69B4",
            "herb": "#3ECF3E",
            "ore": "#238DF7",
            "lumber": "#CFAF08",
        },
    ),
    (
        "ObjectIconsAtlas_fishBlue_herbGreen_oreYellow_lumberPink.tga",
        {
            "fish": "#238DF7",
            "herb": "#3ECF3E",
            "ore": "#CFAF08",
            "lumber": "#FF69B4",
        },
    ),
]

OUTLINE_PRESET = "ObjectIconsAtlas_outlineWhite_fillBlack.tga"


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def tint_region(img, rect, hex_color):
    x, y, w, h = rect
    r_t, g_t, b_t = hex_to_rgb(hex_color)
    px = img.load()

    for yy in range(y, y + h):
        for xx in range(x, x + w):
            r, g, b, a = px[xx, yy]
            if a == 0:
                continue
            lum = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
            nr = int(r_t * lum)
            ng = int(g_t * lum)
            nb = int(b_t * lum)
            px[xx, yy] = (nr, ng, nb, a)


def outline_region(img, source, rect):
    x, y, w, h = rect
    dst = img.load()
    src = source.load()

    # Keep only the main connected alpha shape in this icon cell.
    alpha_points = set()
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            if src[xx, yy][3] > 0:
                alpha_points.add((xx, yy))

    keep = set()
    visited = set()
    best = []
    for pt in alpha_points:
        if pt in visited:
            continue
        q = deque([pt])
        visited.add(pt)
        comp = []
        while q:
            cx, cy = q.popleft()
            comp.append((cx, cy))
            for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                if (nx, ny) in alpha_points and (nx, ny) not in visited:
                    visited.add((nx, ny))
                    q.append((nx, ny))
        if len(comp) > len(best):
            best = comp
    keep.update(best)

    for yy in range(y, y + h):
        for xx in range(x, x + w):
            r, g, b, a = src[xx, yy]
            if (xx, yy) not in keep:
                dst[xx, yy] = (r, g, b, 0)
                continue

            # Inverted grayscale from Blizzard icon:
            # black outline -> white, bright yellow fill -> dark gray/black.
            lum = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
            inv = int((1.0 - lum) * 255)
            dst[xx, yy] = (inv, inv, inv, a)


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    base = Image.open(SRC).convert("RGBA")

    for filename, colors in PRESETS:
        img = base.copy()
        for key, rect in RECTS.items():
            tint_region(img, rect, colors[key])
        out_path = OUT_DIR / filename
        img.save(out_path, format="TGA")
        print(f"Wrote {out_path}")

    outline = base.copy()
    for rect in RECTS.values():
        outline_region(outline, base, rect)
    out_path = OUT_DIR / OUTLINE_PRESET
    outline.save(out_path, format="TGA")
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
