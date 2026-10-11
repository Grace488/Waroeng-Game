#!/usr/bin/env python3
"""
Warung Pixel - Sprite Generator
Generates pixel-art assets for Godot 4 using Pillow.
All sprites are drawn pixel-by-pixel from ASCII grids and a strictly defined color palette.
No AI image generation is used.
"""

# pyright: reportMissingImports=false
import os
import sys

# Ensure Anaconda Lib/site-packages is accessible even if running under another interpreter
for _site in [
    r"C:\Users\acer\anaconda3\Lib\site-packages",
    r"C:\Users\acer\anaconda3\lib\site-packages",
]:
    if os.path.isdir(_site) and _site not in sys.path:
        sys.path.insert(0, _site)

# Ensure Anaconda DLLs can be loaded on Windows when running directly
_base_dir = os.path.dirname(sys.executable)
for _sub in ["Library/bin", "Library/mingw-w64/bin", "Library/usr/bin", "bin", ""]:
    _p = os.path.join(_base_dir, _sub.replace("/", os.sep))
    if os.path.isdir(_p):
        if hasattr(os, "add_dll_directory"):
            try:
                os.add_dll_directory(_p)
            except Exception:
                pass
        if _p not in os.environ.get("PATH", ""):
            os.environ["PATH"] = _p + os.pathsep + os.environ.get("PATH", "")

from PIL import Image  # type: ignore  # noqa: F401

# ==============================================================================
# COLOR PALETTE (12 to 24 colors)
# Strictly defined 23 distinct opaque colors + transparent.
# ==============================================================================
PALETTE = {
    ".": (0, 0, 0, 0),          # 0: Transparent
    "#": (26, 18, 24, 255),      # 1: Dark outline (#1a1218)
    "r": (214, 76, 42, 255),     # 2: Orange-red roof / warm accents
    "R": (156, 46, 30, 255),     # 3: Roof dark shadow / deep terracotta
    "h": (245, 122, 72, 255),    # 4: Roof highlight / bright terracotta
    "w": (124, 74, 46, 255),     # 5: Teak wood / counter / furniture
    "W": (74, 42, 28, 255),      # 6: Dark timber / wood shadow
    "L": (182, 120, 74, 255),    # 7: Light wood / shelf / stool highlight
    "b": (226, 182, 132, 255),   # 8: Bamboo wall / warm interior planks
    "s": (226, 68, 38, 255),     # 9: Player red-orange shirt / lantern paper
    "S": (168, 42, 26, 255),     # 10: Shirt shadow / lantern frame
    "k": (255, 206, 162, 255),   # 11: Chibi warm skin tone
    "K": (220, 160, 120, 255),   # 12: Skin shadow / blush
    "H": (30, 26, 32, 255),      # 13: Jet black hair / pupils
    "E": (64, 54, 68, 255),      # 14: Hair sheen / highlight
    "a": (246, 244, 240, 255),   # 15: Crisp white apron / sign text
    "A": (195, 192, 202, 255),   # 16: Apron shadow / bowl shading
    "y": (255, 214, 72, 255),    # 17: Paper lantern glow / stars / flame
    "g": (138, 212, 222, 255),   # 18: Glass jar cyan reflection / window glass
    "o": (235, 168, 48, 255),    # 19: Crunchy kerupuk / noodles / snacks
    "n": (18, 22, 44, 255),      # 20: Night sky navy / deepest shadow
    "m": (108, 114, 128, 255),   # 21: Metal stove / pot / iron brackets
    "G": (58, 134, 68, 255),     # 22: Banana leaf / garnish / plants
    "f": (24, 20, 30, 255),      # 23: Plain floor dark neutral (bottom 70px)
}

# ==============================================================================
# ASCII GRID DRAWING UTILITIES
# ==============================================================================

def create_image_from_grid(grid, palette, width=None, height=None, bg_color=(0, 0, 0, 0)):
    """Creates a PIL Image from an ASCII pixel grid."""
    lines = [line.strip() for line in grid if line.strip()]
    h = height or len(lines)
    w = width or max(len(l) for l in lines)
    img = Image.new("RGBA", (w, h), bg_color)
    pixels = img.load()
    for y, line in enumerate(lines):
        if y >= h:
            break
        for x, char in enumerate(line):
            if x >= w:
                break
            if char in palette:
                color = palette[char]
                if color[3] > 0:
                    pixels[x, y] = color
    return img


def blit_grid(target_img, grid, palette, offset_x, offset_y):
    """Blits an ASCII grid onto a target PIL Image at (offset_x, offset_y)."""
    target_w, target_h = target_img.size
    pixels = target_img.load()
    lines = [line.strip() for line in grid if line.strip()]
    for dy, line in enumerate(lines):
        y = offset_y + dy
        if y < 0 or y >= target_h:
            continue
        for dx, char in enumerate(line):
            x = offset_x + dx
            if x < 0 or x >= target_w:
                continue
            if char in palette:
                color = palette[char]
                if color[3] > 0:
                    pixels[x, y] = color


def mirror_horizontal(grid):
    """Horizontally mirrors an ASCII grid (for clean left/right walk cycles)."""
    return [line[::-1] for line in grid]


# ==============================================================================
# SPRITE 1: PLAYER SHEET (128x128, 4x4 grid of 32x32 frames)
# Rows: Down (0..3), Left (4..7), Right (8..11), Up (12..15)
# Character: Chibi Indonesian food stall owner
# Short black hair, red-orange shirt, small white apron, brown sandals, 1-pixel dark outline.
# Arms and legs visibly alternate between frames.
# Body bobs by 1 pixel on step frames (frames 1 & 3).
# All frames aligned to the same baseline (feet touch Y = 28).
# ==============================================================================

# DOWN: Idle (Frame 0) - Symmetrical standing pose, baseline Y=28
DOWN_F0 = [
    "................................",
    "................................",
    "................................",
    "................................",
    ".............######.............",
    "............#HHHHHH#............",
    "...........#HHHEEHHH#...........",
    "..........#HHHHHHHHHH#..........",
    "..........#HHHkkkkHHH#..........",
    "..........#HkkkkkkkkH#..........",
    "..........#Hk#kkkk#kH#..........",  # Eyes at X=13, 18
    "..........#kKkk##kkKk#..........",  # Cheeks & smile
    "...........#kkkkkkkk#...........",
    "............#ssssss#............",  # Red-orange shirt collar
    "..........#sssaaaasss#..........",  # White apron bib
    ".........#sssaaaaaasss#.........",
    ".........#kssaaaaaassk#.........",  # Hands at sides
    ".........#kssAAAAAAssk#.........",  # Apron shading
    "..........#ssaaaaaass#..........",
    "...........#sAAAAAAs#...........",  # Waist tie
    "...........#WWWWWWWW#...........",  # Pants
    "...........#WWW##WWW#...........",
    "...........#WWW##WWW#...........",
    "...........#kkk##kkk#...........",  # Ankles
    "..........#LLk####kLL#..........",  # Brown sandal straps
    "..........#WWW####WWW#..........",  # Sandals
    "..........#WWW####WWW#..........",
    "..........#WW######WW#..........",
    "...........##......##...........",  # Soles at baseline Y=28
    "................................",
    "................................",
    "................................",
]

# DOWN: Walk 1 (Frame 1) - Left step forward, right back, arms swing, body bobs down 1px
DOWN_F1 = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    ".............######.............",  # Head bobs down 1px to Y=5
    "............#HHHHHH#............",
    "...........#HHHEEHHH#...........",
    "..........#HHHHHHHHHH#..........",
    "..........#HHHkkkkHHH#..........",
    "..........#HkkkkkkkkH#..........",
    "..........#Hk#kkkk#kH#..........",
    "..........#kKkk##kkKk#..........",
    "...........#kkkkkkkk#...........",
    "............#ssssss#............",
    ".........#ksssaaaasss#..........",  # Left arm swinging back/up (hand at Y=15)
    ".........#kssaaaaaasss#.........",
    "..........#ssaaaaaasssk#........",  # Right arm swinging forward/down (hand at Y=17)
    "..........#ssAAAAAAssk#.........",
    "...........#saaaaaass#..........",
    "............#WWWWWW#............",
    "...........#WWWW##WW#...........",
    "..........#WWWW###WW#...........",  # Left leg forward
    ".........#kkkk####kk#...........",  # Right leg lifted back
    "........#LLkk####LL#............",
    "........#WWk#####WW#............",  # Right foot raised to Y=26
    "........#WW#####WW#.............",
    ".........##.....##..............",  # Left foot contacts ground at Y=28
    "................................",
    "................................",
    "................................",
    "................................",
]

# DOWN: Walk 2 (Frame 2) - Passing pose, body returns to baseline Y=28
DOWN_F2 = [
    "................................",
    "................................",
    "................................",
    "................................",
    ".............######.............",  # Head returns to baseline Y=4
    "............#HHHHHH#............",
    "...........#HHHEEHHH#...........",
    "..........#HHHHHHHHHH#..........",
    "..........#HHHkkkkHHH#..........",
    "..........#HkkkkkkkkH#..........",
    "..........#Hk#kkkk#kH#..........",
    "..........#kKkk##kkKk#..........",
    "...........#kkkkkkkk#...........",
    "............#ssssss#............",
    "..........#sssaaaasss#..........",
    ".........#sssaaaaaasss#.........",
    ".........#kssaaaaaassk#.........",
    ".........#kssAAAAAAssk#.........",
    "..........#ssaaaaaass#..........",
    "...........#sAAAAAAs#...........",
    "...........#WWWWWWWW#...........",
    "............#WWWWWW#............",  # Legs passing together
    "............#WWWWWW#............",
    "............#kkkkkk#............",
    "...........#LLk##kLL#...........",
    "...........#WWk##kWW#...........",
    "...........#WWk##kWW#...........",
    "...........#WWk##kWW#...........",
    "............###..###............",  # Soles touch Y=28
    "................................",
    "................................",
    "................................",
]

# DOWN: Walk 3 (Frame 3) - Right step forward, left back, arms swing, body bobs down 1px
DOWN_F3 = mirror_horizontal(DOWN_F1)

# LEFT: Idle (Frame 4) - Facing left standing at baseline Y=28
LEFT_F0 = [
    "................................",
    "................................",
    "................................",
    "................................",
    "............######..............",
    "...........#HHHHHH#.............",
    "..........#HHHHHHEH#............",
    ".........#HH#kkkkHH#............",
    ".........#Hkk#kkkHH#............",  # Side eye at X=12
    ".........#kkkkkkkHH#............",
    ".........#kKkkkkkHH#............",  # Blush on cheek
    "..........#k##kkkH#.............",
    "...........#sssss#..............",
    "..........#saaaaass#............",  # Apron on front (left), shirt on back (right)
    ".........#ksaaaaass#............",
    ".........#ksaaaaassa#...........",
    "..........#saaaaassA#...........",  # Apron tie bow at back
    "..........#ksAAAass#............",
    "...........#saaaass#............",
    "............#WWWWW#.............",
    "............#WWWWW#.............",
    "............#W###W#.............",
    "............#W###W#.............",
    "............#k###k#.............",
    "...........#LL###LL#............",  # Brown sandals
    "...........#WW###WW#............",
    "...........#WW###WW#............",
    "...........#WW###WW#............",
    "............######..............",  # Soles at baseline Y=28
    "................................",
    "................................",
    "................................",
]

# LEFT: Walk 1 (Frame 5) - Left leg strides forward, right leg back, arms swing, bobs down 1px
LEFT_F1 = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "............######..............",  # Bobbed down 1px
    "...........#HHHHHH#.............",
    "..........#HHHHHHEH#............",
    ".........#HH#kkkkHH#............",
    ".........#Hkk#kkkHH#............",
    ".........#kkkkkkkHH#............",
    ".........#kKkkkkkHH#............",
    "..........#k##kkkH#.............",
    "...........#sssss#..............",
    ".........#ksaasssssk#...........",  # Front arm forward, back arm back
    ".........#ksaaaaassa#...........",
    "..........#saaaaassA#...........",
    "..........#sAAAAass#............",
    "...........#saaaass#............",
    "............#WWWW#..............",
    "...........#WW##WW#.............",  # Wide stride
    "..........#WW####WW#............",
    ".........#kk######kk#...........",
    ".........#LL######LL#...........",
    ".........#WW######WW#...........",  # Right leg trailing back, raised
    ".........#WW#######W#...........",
    "..........##....................",  # Left foot contacts ground at Y=28
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
]

# LEFT: Walk 2 (Frame 6) - Passing pose, body returns to baseline Y=28
LEFT_F2 = [
    "................................",
    "................................",
    "................................",
    "................................",
    "............######..............",  # Back to baseline Y=4
    "...........#HHHHHH#.............",
    "..........#HHHHHHEH#............",
    ".........#HH#kkkkHH#............",
    ".........#Hkk#kkkHH#............",
    ".........#kkkkkkkHH#............",
    ".........#kKkkkkkHH#............",
    "..........#k##kkkH#.............",
    "...........#sssss#..............",
    "..........#saaaaass#............",
    ".........#ksaaaaass#............",
    ".........#ksaaaaassa#...........",
    "..........#saaaaassA#...........",
    "..........#ksAAAass#............",
    "...........#saaaass#............",
    "............#WWWWW#.............",
    "............#WWWWW#.............",
    "............#WWWWW#.............",  # Legs passing together
    "............#kkkkk#.............",
    "............#LLLLL#.............",
    "...........#WWWWW#..............",
    "...........#WWWWW#..............",
    "...........#WWWWW#..............",
    "............#####...............",  # Soles at baseline Y=28
    "................................",
    "................................",
    "................................",
]

# LEFT: Walk 3 (Frame 7) - Right leg strides forward, left leg back, bobs down 1px
LEFT_F3 = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "............######..............",  # Bobbed down 1px
    "...........#HHHHHH#.............",
    "..........#HHHHHHEH#............",
    ".........#HH#kkkkHH#............",
    ".........#Hkk#kkkHH#............",
    ".........#kkkkkkkHH#............",
    ".........#kKkkkkkHH#............",
    "..........#k##kkkH#.............",
    "...........#sssss#..............",
    "..........#kssssaaask#..........",  # Arms reversed
    "..........#ssaaaaassa#..........",
    "..........#ssaaaaassA#..........",
    "...........#sAAAass#............",
    "...........#saaaass#............",
    "............#WWWW#..............",
    "...........#WW##WW#.............",  # Right stride forward
    "..........#WW####WW#............",
    ".........#kk######kk#...........",
    ".........#LL######LL#...........",
    ".........#WW######WW#...........",  # Left leg trailing back, raised
    "..........#W#######WW#..........",
    "...................##...........",  # Contacts ground at Y=28
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
]

# RIGHT: Walk-cycle (Frames 8..11) - Exact horizontal mirrors of Left
RIGHT_F0 = mirror_horizontal(LEFT_F0)
RIGHT_F1 = mirror_horizontal(LEFT_F1)
RIGHT_F2 = mirror_horizontal(LEFT_F2)
RIGHT_F3 = mirror_horizontal(LEFT_F3)

# UP: Idle (Frame 12) - Back view standing at baseline Y=28
UP_F0 = [
    "................................",
    "................................",
    "................................",
    "................................",
    ".............######.............",
    "............#HHHHHH#............",
    "...........#HHHEEHHH#...........",
    "..........#HHHHHHHHHH#..........",
    "..........#HHHHHHHHHH#..........",
    "..........#HHHHHHHHHH#..........",
    "..........#HHHHHHHHHH#..........",
    "..........#HHHHHHHHHH#..........",
    "...........#HHHHHHHH#...........",
    "............#ssssss#............",  # Red-orange shirt
    "..........#ssssssssss#..........",
    ".........#ssssssssssss#.........",
    ".........#kssssssssssk#.........",
    ".........#kssAAssAAssk#.........",  # Apron cross straps & knot on back
    "..........#ssaaaaaass#..........",
    "...........#sAAAAAAs#...........",
    "...........#WWWWWWWW#...........",  # Pants
    "...........#WWW##WWW#...........",
    "...........#WWW##WWW#...........",
    "...........#kkk##kkk#...........",
    "..........#LLk####kLL#..........",  # Sandals
    "..........#WWW####WWW#..........",
    "..........#WWW####WWW#..........",
    "..........#WW######WW#..........",
    "...........##......##...........",  # Soles at baseline Y=28
    "................................",
    "................................",
    "................................",
]

# UP: Walk 1 (Frame 13) - Left step forward, right back, arms swing, bobs down 1px
UP_F1 = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    ".............######.............",  # Bobbed down 1px
    "............#HHHHHH#............",
    "...........#HHHEEHHH#...........",
    "..........#HHHHHHHHHH#..........",
    "..........#HHHHHHHHHH#..........",
    "..........#HHHHHHHHHH#..........",
    "..........#HHHHHHHHHH#..........",
    "..........#HHHHHHHHHH#..........",
    "...........#HHHHHHHH#...........",
    "............#ssssss#............",
    ".........#kssssssssss#..........",  # Left arm swinging up
    ".........#ksssssssssss#.........",
    "..........#sssssssssssk#........",  # Right arm swinging down
    "..........#ssAAssAAssk#.........",
    "...........#ssaaaaass#..........",
    "............#WWWWWW#............",
    "...........#WWWW##WW#...........",
    "..........#WWWW###WW#...........",  # Left leg forward
    ".........#kkkk####kk#...........",  # Right leg lifted back
    "........#LLkk####LL#............",
    "........#WWk#####WW#............",  # Right foot raised to Y=26
    "........#WW#####WW#.............",
    ".........##.....##..............",  # Left foot touches down at Y=28
    "................................",
    "................................",
    "................................",
    "................................",
]

# UP: Walk 2 (Frame 14) - Passing pose, body returns to baseline Y=28
UP_F2 = [
    "................................",
    "................................",
    "................................",
    "................................",
    ".............######.............",  # Back to baseline Y=4
    "............#HHHHHH#............",
    "...........#HHHEEHHH#...........",
    "..........#HHHHHHHHHH#..........",
    "..........#HHHHHHHHHH#..........",
    "..........#HHHHHHHHHH#..........",
    "..........#HHHHHHHHHH#..........",
    "..........#HHHHHHHHHH#..........",
    "...........#HHHHHHHH#...........",
    "............#ssssss#............",
    "..........#ssssssssss#..........",
    ".........#ssssssssssss#.........",
    ".........#kssssssssssk#.........",
    ".........#kssAAssAAssk#.........",
    "..........#ssaaaaaass#..........",
    "...........#sAAAAAAs#...........",
    "...........#WWWWWWWW#...........",
    "............#WWWWWW#............",  # Passing legs
    "............#WWWWWW#............",
    "............#kkkkkk#............",
    "...........#LLk##kLL#...........",
    "...........#WWk##kWW#...........",
    "...........#WWk##kWW#...........",
    "...........#WWk##kWW#...........",
    "............###..###............",  # Soles touch Y=28
    "................................",
    "................................",
    "................................",
]

# UP: Walk 3 (Frame 15) - Right step forward, left back, bobs down 1px
UP_F3 = mirror_horizontal(UP_F1)

PLAYER_FRAMES = [
    # Row 0: Down (frames 0..3)
    DOWN_F0, DOWN_F1, DOWN_F2, DOWN_F3,
    # Row 1: Left (frames 4..7)
    LEFT_F0, LEFT_F1, LEFT_F2, LEFT_F3,
    # Row 2: Right (frames 8..11)
    RIGHT_F0, RIGHT_F1, RIGHT_F2, RIGHT_F3,
    # Row 3: Up (frames 12..15)
    UP_F0, UP_F1, UP_F2, UP_F3,
]


def generate_player_sheet():
    """Generates 128x128 player spritesheet (4x4 grid of 32x32 frames)."""
    sheet = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    for idx, frame_grid in enumerate(PLAYER_FRAMES):
        col = idx % 4
        row = idx // 4
        ox = col * 32
        oy = row * 32
        blit_grid(sheet, frame_grid, PALETTE, ox, oy)
    return sheet


# ==============================================================================
# SPRITE 2: WARUNG BUILDING (96x96 transparent PNG)
# Indonesian warung building:
# - Wooden walls with corner timber posts
# - Orange-red tin roof with corrugated highlights and eaves
# - Wooden counter with Indonesian glass krupuk jars, candy jar, bottles, platter
# - Hanging paper lantern with warm golden glow
# - Sign reading "WARUNG" in pixel font
# - 1-pixel dark outline
# ==============================================================================

def generate_warung_building():
    """Generates 96x96 pixel art Indonesian warung building."""
    img = Image.new("RGBA", (96, 96), (0, 0, 0, 0))

    # --- 1. Orange-red tin roof (pitched roof with corrugation stripes) ---
    roof_grid = [
        "...................################################################...................",
        "..................#hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh#..................",
        ".................#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#.................",
        "................#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#................",
        "...............#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#...............",
        "..............#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#..............",
        ".............#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#.............",
        "............#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#............",
        "...........#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#...........",
        "..........#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#..........",
        ".........#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#.........",
        "........#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#........",
        ".......#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#.......",
        "......#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#......",
        ".....#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#.....",
        "....#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#....",
        "...#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#...",
        "..#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#..",
        ".#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#.",
        "#hrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhrhr#",
        "#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#",
        "######################################################################################",
        ".#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#W#.",
    ]
    blit_grid(img, roof_grid, PALETTE, 5, 8)

    # --- 2. Main Wooden Structure, Opening, Counter, and Foundation ---
    walls_grid = [
        # Y=30..32: Top crossbeam
        "#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#",
        "#wLwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwLwww#",
        "#W#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#W#",
        # Y=33..43: Interior upper wall behind counter
        "#wL#bwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbw#Lw#",
        "#wL#wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww#Lw#",
        "#wL#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#Lw#",
        "#wL#bwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbw#Lw#",
        "#wL#wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww#Lw#",
        "#wL#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#Lw#",
        "#wL#bwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbw#Lw#",
        "#wL#wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww#Lw#",
        "#wL#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#Lw#",
        "#wL#bwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbw#Lw#",
        "#wL#wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww#Lw#",
        # Y=44..48: Inside shelf with spice jars & bowls
        "#wL##########################################################################Lw#",
        "#wL#LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL#Lw#",
        "#wL#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#Lw#",
        "#wL##########################################################################Lw#",
        # Y=49..65: Lower opening space leading down to counter
        "#wL#bwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbw#Lw#",
        "#wL#wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww#Lw#",
        "#wL#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#Lw#",
        "#wL#bwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbw#Lw#",
        "#wL#wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww#Lw#",
        "#wL#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#Lw#",
        "#wL#bwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbw#Lw#",
        "#wL#wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww#Lw#",
        "#wL#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#Lw#",
        "#wL#bwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbw#Lw#",
        "#wL#wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww#Lw#",
        "#wL#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#Lw#",
        "#wL#bwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbw#Lw#",
        "#wL#wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww#Lw#",
        "#wL#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#Lw#",
        "#wL#bwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbw#Lw#",
        "#wL#wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww#Lw#",
        "#wL#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#Lw#",
        "#wL#bwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbw#Lw#",
        # Y=67..72: Teak Countertop ledge
        "################################################################################",
        "#LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL#",
        "#wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww#",
        "#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#",
        "################################################################################",
        # Y=73..86: Lower front wooden wall siding
        "#wLwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwLwww#",
        "#wLwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwLwww#",
        "#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#",
        "#wLwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwLwww#",
        "#wLwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwLwww#",
        "#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#",
        "#wLwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwLwww#",
        "#wLwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwLwww#",
        "#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#",
        "#wLwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwLwww#",
        "#wLwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwLwww#",
        "#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#",
        "#wLwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwLwww#",
        "#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#",
        # Y=87..89: Stone foundation blocks
        "#mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm#",
        "#m##m##m##m##m##m##m##m##m##m##m##m##m##m##m##m##m##m##m##m##m##m##m##m##m##m#",
        "################################################################################",
    ]
    blit_grid(img, walls_grid, PALETTE, 8, 30)

    # --- 3. Wooden Signboard "WARUNG" mounted under roof ridge ---
    sign_grid = [
        "###################################################",
        "#LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL#",
        "#L###############################################L#",
        "#L#wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww#L#",
        "#L#ww#...#w.##.w###.w#..#w#..#w.###wwwwwwwwwwwww#L#",
        "#L#ww#...#w#..#w#..#w#..#w##.#w#...wwwwwwwwwwwww#L#",
        "#L#ww#.#.#w####w###.w#..#w#.##w#.##wwwwwwwwwwwww#L#",
        "#L#ww##.##w#..#w#.#.w#..#w#..#w#..#wwwwwwwwwwwww#L#",
        "#L#ww#...#w#..#w#..#w.##.w#..#w.###wwwwwwwwwwwww#L#",
        "#L#wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww#L#",
        "#L#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#L#",
        "#LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL#",
        "###################################################",
    ]
    sign_white_grid = [
        "...................................................",
        "...................................................",
        "...................................................",
        "...................................................",
        ".....a...a..aa..aaa..a..a.a..a..aaa................",
        ".....a...a.a..a.a..a.a..a.aa.a.a...................",
        ".....a.a.a.aaaa.aaa..a..a.a.aa.a.aa................",
        ".....aa.aa.a..a.a.a..a..a.a..a.a..a................",
        ".....a...a.a..a.a..a..aa..a..a..aaa................",
        "...................................................",
        "...................................................",
        "...................................................",
        "...................................................",
    ]
    blit_grid(img, sign_grid, PALETTE, 23, 24)
    blit_grid(img, sign_white_grid, PALETTE, 23, 24)

    # --- 4. Hanging Paper Lantern on Left Eave ---
    lantern_grid = [
        "....#....",
        "....#....",
        "....#....",
        "...###...",
        "..#SSS#..",
        ".#syyys#.",
        "#syyyyys#",
        "#syyoyys#",
        "#syooyys#",
        "#syyoyys#",
        "#syyyyys#",
        ".#syyys#.",
        "..#SSS#..",
        "...###...",
        "....#....",
        "...#y#...",
        "...#W#...",
    ]
    blit_grid(img, lantern_grid, PALETTE, 11, 33)

    # --- 5. Glass Jars & Snacks on Counter ---
    # Large Indonesian glass kerupuk jar with red lid (Left)
    jar_left_grid = [
        "....####....",
        "...#SSSS#...",
        "..#ssssss#..",
        "..#ssssss#..",
        "...######...",
        "..#gggggg#..",
        ".#gggaaagg#.",
        "#gggooogggg#",
        "#ggoooyoggg#",
        "#goooooyogg#",
        "#goyoooyogg#",
        "#goooyooogg#",
        "#ggoooooggg#",
        ".#gggggggg#.",
        "..########..",
    ]
    blit_grid(img, jar_left_grid, PALETTE, 25, 53)

    # Medium glass snack jar with yellow chips (Center-Left)
    jar_mid_grid = [
        "...####...",
        "..#mmmm#..",
        "...####...",
        "..#gggg#..",
        ".#gaaagg#.",
        "#gyyyoygg#",
        "#gyoooygg#",
        "#goyyoygg#",
        "#gyoyyygg#",
        ".#gggggg#.",
        "..######..",
    ]
    blit_grid(img, jar_mid_grid, PALETTE, 40, 57)

    # Condiment bottles (Kecap manis & Sambal) on right
    bottles_grid = [
        "....#.....#....",
        "...#W#...#s#...",
        "...#W#...#s#...",
        "..#WWW#.#sss#..",
        "..#WWW#.#sss#..",
        "..#WaW#.#sas#..",
        "..#WWW#.#sss#..",
        "..#WWW#.#sss#..",
        "..#WWW#.#sss#..",
        "...###...###...",
    ]
    blit_grid(img, bottles_grid, PALETTE, 64, 58)

    # Small display basket with banana leaf & snacks
    basket_grid = [
        "..#GGGGGG#..",
        ".#GGGoGGGGG#.",
        "#GGooyooGGGG#",
        "#WWWWWWWWWW#",
        ".##########.",
    ]
    blit_grid(img, basket_grid, PALETTE, 52, 63)

    return img


# ==============================================================================
# SPRITE 3: WARUNG INTERIOR (640x360 background PNG)
# Indonesian warung interior:
# - Wooden counter
# - Stove with pot, gas flame, and rising pixel steam
# - Shelves with traditional glass krupuk jars, spice containers, and bottles
# - Warm glowing hanging paper lantern
# - Window looking out into night sky with moon and stars
# - 3 wooden customer stools (dingklik) firmly on the floor
# - Plain floor at the bottom 70 pixels (Y = 290..359 solid neutral color)
# ==============================================================================

def generate_warung_interior():
    """Generates 640x360 pixel art interior background."""
    img = Image.new("RGBA", (640, 360), (0, 0, 0, 0))
    pixels = img.load()

    # --- 1. Ceiling & Wall Base ---
    # Wall planks (warm bamboo/timber panels) from Y = 0 to 220
    for y in range(0, 220):
        is_seam = (y % 16 == 0)
        is_highlight = (y % 16 == 1)
        for x in range(640):
            if is_seam:
                pixels[x, y] = PALETTE["W"]
            elif is_highlight:
                pixels[x, y] = PALETTE["L"]
            else:
                pixels[x, y] = PALETTE["b"] if (x + y * 3) % 29 != 0 else PALETTE["w"]

    # Floor base from Y = 220 to 290 across ALL X = 0..640
    for y in range(220, 290):
        is_floor_seam = (y % 14 == 0)
        is_floor_highlight = (y % 14 == 1)
        for x in range(640):
            if is_floor_seam:
                pixels[x, y] = PALETTE["W"]
            elif is_floor_highlight:
                pixels[x, y] = PALETTE["L"]
            else:
                pixels[x, y] = PALETTE["w"]

    # Heavy ceiling beams at Y = 0..18
    for y in range(0, 18):
        for x in range(640):
            if y == 0 or y == 17:
                pixels[x, y] = PALETTE["#"]
            elif y == 1:
                pixels[x, y] = PALETTE["L"]
            elif y < 14:
                pixels[x, y] = PALETTE["w"]
            else:
                pixels[x, y] = PALETTE["W"]

    # Vertical timber rafter beams hanging from ceiling
    for rx in [80, 260, 440, 600]:
        for y in range(18, 48):
            for dx in range(-4, 5):
                if dx in (-4, 4) or y == 47:
                    pixels[rx + dx, y] = PALETTE["#"]
                elif dx == -3:
                    pixels[rx + dx, y] = PALETTE["L"]
                else:
                    pixels[rx + dx, y] = PALETTE["w"]

    # --- 2. Window on Left Wall (X = 40..144, Y = 32..136) ---
    win_grid = [
        "################################################################################################",
        "#LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL#",
        "#L############################################################################################L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnaynnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnaynnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnyannnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnyannnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnyyyynnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnyyyyyyyynnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnyyyyyyyyynnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnyyyynnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnyyynnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnyyynnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnyyyynnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnaynnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnyyyyyyyyynnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnyannnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnyyyyyyyynnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnyyyynnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnaynnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnyannnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L############################################################################################L#",
        "#L#LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL#L#",
        "#L############################################################################################L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnaynnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnyannnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnaynnnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnyannnnnnnn#L#",
        "#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#",
        "#L#nnnnnn###nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnn###nnnnnnnnnnn#L#",
        "#L#nnnnn#####nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnnn#####nnnnnnnnnn#L#",
        "#L#nnnn#######nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnnn#######nnnnnnnnn#L#",
        "#L#nnn#########nnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnnn#########nnnnnnnn#L#",
        "#L#nn###########nnnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnnn###########nnnnnnn#L#",
        "#L#n#############nnnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnnn#############nnnnnn#L#",
        "#L################nnnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnnn###############nnnnn#L#",
        "#L#################nnnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnnn#################nnnn#L#",
        "#L##################nnnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnnn##################nnnn#L#",
        "#L###################nnnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnnn####################nnn#L#",
        "#L####################nnnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnnn######################nn#L#",
        "#L#####################nnnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnnn########################n#L#",
        "#L######################nnnnnnnnnnnnnnnnnnnnn#L#nnnnnnnnnnnnnnnnnn##########################L#",
        "#L############################################################################################L#",
        "#LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL#",
        "#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#",
        "################################################################################################",
    ]
    blit_grid(img, win_grid, PALETTE, 44, 38)

    # --- 3. Shelves with Jars on Back Wall ---
    def draw_shelf(start_x, end_x, shelf_y):
        for x in range(start_x, end_x):
            pixels[x, shelf_y] = PALETTE["#"]
            pixels[x, shelf_y + 1] = PALETTE["L"]
            pixels[x, shelf_y + 2] = PALETTE["w"]
            pixels[x, shelf_y + 3] = PALETTE["W"]
            pixels[x, shelf_y + 4] = PALETTE["#"]
        for bx in [start_x + 35, (start_x + end_x) // 2, end_x - 35]:
            bracket_grid = [
                "###",
                "#m#",
                "#m#",
                "##.",
                "#m.",
                "#..",
            ]
            blit_grid(img, bracket_grid, PALETTE, bx, shelf_y + 5)

    # Upper Shelf (Y = 62)
    draw_shelf(200, 610, 62)
    # Lower Shelf (Y = 126)
    draw_shelf(200, 610, 126)

    # Jars & Items on Upper Shelf
    krupuk_jar_grid = [
        "......######......",
        ".....#SSSSSS#.....",
        "....#ssssssss#....",
        "....#ssssssss#....",
        ".....########.....",
        "....#gggggggg#....",
        "...#gggaaaaagg#...",
        "..#gggaaaaaaagg#..",
        "..#gggooooygggg#..",
        ".#ggooooyyyooygg#.",
        ".#gyooyooooyyygg#.",
        ".#gyoyoyoyoooygg#.",
        ".#gooooyyoooyogg#.",
        ".#gyooyoooyoyygg#.",
        ".#gyyyoooyoooygg#.",
        ".#gooyyoooyyoygg#.",
        ".#ggooooooooygg#..",
        "..#gggggggggggg#..",
        "...############...",
    ]
    blit_grid(img, krupuk_jar_grid, PALETTE, 220, 44)
    blit_grid(img, krupuk_jar_grid, PALETTE, 255, 44)
    blit_grid(img, krupuk_jar_grid, PALETTE, 290, 44)

    # Spice Jars on Upper Shelf
    spice_jars_grid = [
        "..####....####....####....####..",
        ".#mmmm#..#mmmm#..#mmmm#..#mmmm#.",
        "..####....####....####....####..",
        ".#gggg#..#gggg#..#gggg#..#gggg#.",
        "#gaaaag##gaaaag##gaaaag##gaaaag#",
        "#gyyyyg##goooog##grrrrg##gGGGGg#",
        "#gyyyyg##goooog##grrrrg##gGGGGg#",
        "#gyyyyg##goooog##grrrrg##gGGGGg#",
        "#gyyyyg##goooog##grrrrg##gGGGGg#",
        "#gyyyyg##goooog##grrrrg##gGGGGg#",
        ".#gggg#..#gggg#..#gggg#..#gggg#.",
        "..####....####....####....####..",
    ]
    blit_grid(img, spice_jars_grid, PALETTE, 350, 51)

    # Enamel tea kettle on Upper Shelf
    kettle_grid = [
        "....########....",
        "...#mmmmmmmm#...",
        "..#m########m#..",
        "..#m#......#m#..",
        "..#m#..##..#m#..",
        ".#mmm##mm##mmm#.",
        "#mmmmmmmmmmmmmm#",
        "#mGGGGGGGGGGGGm#",
        "#mGGGGGGGGGGGGm#",
        "#mGGGGGGGGGGGGm#",
        "#mGGGGGGGGGGGGm#",
        ".#mmmmmmmmmmmm#.",
        "..############..",
    ]
    blit_grid(img, kettle_grid, PALETTE, 520, 50)

    # Items on Lower Shelf (Y = 126)
    bottles_row_grid = [
        "...#......#......#......#......#......#...",
        "..#W#....#s#....#s#....#o#....#W#....#s#..",
        "..#W#....#s#....#s#....#o#....#W#....#s#..",
        ".#WWW#..#sss#..#sss#..#ooo#..#WWW#..#sss#.",
        ".#WWW#..#sss#..#sss#..#ooo#..#WWW#..#sss#.",
        ".#WaW#..#sas#..#sas#..#oao#..#WaW#..#sas#.",
        ".#WWW#..#sss#..#sss#..#ooo#..#WWW#..#sss#.",
        ".#WWW#..#sss#..#sss#..#ooo#..#WWW#..#sss#.",
        ".#WWW#..#sss#..#sss#..#ooo#..#WWW#..#sss#.",
        ".#WWW#..#sss#..#sss#..#ooo#..#WWW#..#sss#.",
        ".#WWW#..#sss#..#sss#..#ooo#..#WWW#..#sss#.",
        "..###....###....###....###....###....###..",
    ]
    blit_grid(img, bottles_row_grid, PALETTE, 220, 115)

    # Ceramic bowls on Lower Shelf
    bowls_grid = [
        "...##############...",
        "..#aaaaaaaaaaaaaa#..",
        "..#aAAAAAAAAAAAAa#..",
        "...##############...",
        "..#aaaaaaaaaaaaaa#..",
        "..#aAAAAAAAAAAAAa#..",
        "...##############...",
        "..#aaaaaaaaaaaaaa#..",
        "..#aAAAAAAAAAAAAa#..",
        "...##############...",
    ]
    blit_grid(img, bowls_grid, PALETTE, 430, 117)

    # Glasses on tray
    glasses_grid = [
        "######################",
        "#gggg##gggg##gggg##gg#",
        "#gaag##gaag##gaag##ga#",
        "#gggg##gggg##gggg##gg#",
        "#gggg##gggg##gggg##gg#",
        "#gggg##gggg##gggg##gg#",
        "######################",
        "#LLLLLLLLLLLLLLLLLLLL#",
        "######################",
    ]
    blit_grid(img, glasses_grid, PALETTE, 510, 118)

    # --- 4. Hanging Paper Lantern from Ceiling (X = 320, Y = 18..90) ---
    lantern_big_grid = [
        "......#......",
        "......#......",
        "......#......",
        "......#......",
        "......#......",
        ".....###.....",
        "....#SSS#....",
        "...#sssss#...",
        "..#syyyyys#..",
        ".#syyyyyyys#.",
        "#syyyyooyyys#",
        "#syyyoooyyys#",
        "#syyyyooyyys#",
        "#syyyyyyyyys#",
        "#syyyyooyyys#",
        "#syyyoooyyys#",
        "#syyyyooyyys#",
        "#syyyyyyyyys#",
        ".#syyyyyyys#.",
        "..#syyyyys#..",
        "...#sssss#...",
        "....#SSS#....",
        ".....###.....",
        "......#......",
        ".....#y#.....",
        ".....#W#.....",
    ]
    blit_grid(img, lantern_big_grid, PALETTE, 325, 18)

    # Warm light glow radiating onto adjacent wall
    glow_pixels = [
        (320, 32), (342, 32), (318, 38), (344, 38),
        (316, 44), (346, 44), (316, 50), (346, 50),
    ]
    for gx, gy in glow_pixels:
        pixels[gx, gy] = PALETTE["y"]

    # --- 5. Wooden Serving Counter & Prep Surface (Y = 185..288) ---
    # Top counter ledge (Y = 185..215)
    for y in range(185, 215):
        for x in range(120, 640):
            if y == 185 or y == 214 or x == 120:
                pixels[x, y] = PALETTE["#"]
            elif y in (186, 187) or x == 121:
                pixels[x, y] = PALETTE["L"]
            elif y < 208:
                pixels[x, y] = PALETTE["w"]
            else:
                pixels[x, y] = PALETTE["W"]

    # Counter front facade (Y = 215..288)
    for y in range(215, 289):
        for x in range(120, 640):
            is_v_groove = ((x - 120) % 24 == 0)
            is_v_highlight = ((x - 120) % 24 == 1)
            if y == 288 or x == 120:
                pixels[x, y] = PALETTE["#"]
            elif is_v_groove:
                pixels[x, y] = PALETTE["W"]
            elif is_v_highlight:
                pixels[x, y] = PALETTE["L"]
            else:
                pixels[x, y] = PALETTE["w"]

    # Banana leaf snack platter on counter
    platter_grid = [
        "....############################....",
        "..#GGGGGGGGGGGGGGGGGGGGGGGGGGGGGG#..",
        ".#GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG#.",
        "#GGGGGGGooyyyooGGGGGooyyyooGGGGGGGG#",
        "#GGGGGGooyyyyyooGGGooyyyyyooGGGGGGG#",
        "#GGGGGGooyyyyyooGGGooyyyyyooGGGGGGG#",
        "#GGGGGGGooyyyooGGGGGooyyyooGGGGGGGG#",
        ".#GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG#.",
        "..#GGGGGGGGGGGGGGGGGGGGGGGGGGGGGG#..",
        "....############################....",
    ]
    blit_grid(img, platter_grid, PALETTE, 150, 192)

    # Cutting board and knife
    board_grid = [
        "####################",
        "#LLLLLLLLLLLLLLLLLL#",
        "#LwwwwwwwwwwwwwwwwL#",
        "#Lwwwww###wwwwwwwwL#",
        "#Lwwww#mmm#wwwwwwwL#",
        "#Lwww#mmmmm#wwwwwwL#",
        "#Lww#mmmmmmm#wwwwwL#",
        "#Lw#mmmmmmmmm#wwwwL#",
        "#Lwwwwww#W#wwwwwwwL#",
        "#Lwwwwww#W#wwwwwwwL#",
        "#LLLLLLLLLLLLLLLLLL#",
        "####################",
    ]
    blit_grid(img, board_grid, PALETTE, 260, 192)

    # --- 6. Stove with Pot, Flame, and Rising Steam (X = 460..590, Y = 155..220) ---
    steam_grid = [
        ".........aa.........",
        "........aAAa........",
        ".........aa.........",
        ".......aAAa.........",
        "......aAAa...aa.....",
        ".......aa...aAAa....",
        ".............aa.....",
        "....aa.....aAAa.....",
        "...aAAa...aAAa......",
        "....aa.....aa.......",
        "......aAAa..........",
        ".....aAAa...aa......",
        "......aa...aAAa.....",
        "............aa......",
        "..aa......aAAa......",
        ".aAAa....aAAa.......",
        "..aa......aa........",
    ]
    blit_grid(img, steam_grid, PALETTE, 510, 138)

    pot_grid = [
        "..........##############..........",
        ".........#aaaaaaaaaaaaaa#.........",
        "......####mmmmmmmmmmmmmm####......",
        ".....#mmmm#mmmmmmmmmmmm#mmmm#.....",
        ".....#m##m#oyyyooyyyooy#m##m#.....",
        ".....#mmmm#yoooyyoooyyo#mmmm#.....",
        "......####mmmmmmmmmmmmmm####......",
        ".........#mmmmmmmmmmmmmm#.........",
        ".........#mmmmmmmmmmmmmm#.........",
        ".........#m############m#.........",
        "..........#mmmmmmmmmmmm#..........",
        "...........############...........",
    ]
    blit_grid(img, pot_grid, PALETTE, 500, 168)

    stove_grid = [
        ".............#yy##yy#.............",
        "............#syy##yys#............",
        "##################################",
        "#mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm#",
        "#m##m##m##m##m##m##m##m##m##m##m#",
        "#mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm#",
        "#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#",
        "##################################",
    ]
    blit_grid(img, stove_grid, PALETTE, 495, 180)

    # --- 7. Three Customer Wooden Stools ("Dingklik") ---
    # Resting firmly on the floor at Y = 236..288
    stool_grid = [
        "........################........",
        "......##LLLLLLLLLLLLLLLL##......",
        "....##LLLLLLLLLLLLLLLLLLLL##....",
        "...#LLwwwwwwwwwwwwwwwwwwwwLL#...",
        "..#LwwwwwwwwwwwwwwwwwwwwwwwwL#..",
        "..#LwwwwwwwwwwwwwwwwwwwwwwwwL#..",
        "..#WWWWWWWWWWWWWWWWWWWWWWWWWW#..",
        "...##########################...",
        ".....#WW#..............#WW#.....",
        ".....#WW#..............#WW#.....",
        ".....#ww#..............#ww#.....",
        ".....#ww#..............#ww#.....",
        ".....#ww#..............#ww#.....",
        ".....#ww#..............#ww#.....",
        ".....#ww################ww#.....",
        ".....#ww#LLLLLLLLLLLLLL#ww#.....",
        ".....#ww################ww#.....",
        "....#ww#................#ww#....",
        "....#ww#................#ww#....",
        "....#ww#................#ww#....",
        "....#ww#................#ww#....",
        "...#WW#..................#WW#...",
        "...#WW#..................#WW#...",
        "...#WW#..................#WW#...",
        "...####..................####...",
        "..############################..",  # Cast floor shadow on floor at Y=288
    ]
    for sx in [160, 270, 380]:
        blit_grid(img, stool_grid, PALETTE, sx, 236)

    # --- 8. Plain Floor at Bottom (Bottom 70 pixels: Y = 290..359) ---
    # Strictly solid dark neutral color, keeping it completely plain as required
    for y in range(290, 360):
        for x in range(640):
            pixels[x, y] = PALETTE["f"]

    # Subtle floor transition line at Y = 289
    for x in range(640):
        pixels[x, 289] = PALETTE["#"]

    return img


# ==============================================================================
# MAIN RUNNER
# ==============================================================================

def main():
    print("=" * 60)
    print("WARUNG PIXEL — Pixel Art Sprite Generator")
    print("=" * 60)

    # Palette validation: Must be 12 to 24 colors
    visible_colors = {k: v for k, v in PALETTE.items() if k != "."}
    palette_count = len(visible_colors)
    print(f"Color palette: {palette_count} visible colors defined.")
    assert 12 <= palette_count <= 24, f"Palette count {palette_count} must be between 12 and 24!"

    # Target directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    output_dir = os.path.join(project_root, "assets", "sprites")
    os.makedirs(output_dir, exist_ok=True)

    targets = [
        {
            "name": "player_sheet.png",
            "desc": "Player character walk-cycle spritesheet (4x4 32x32 frames)",
            "fn": generate_player_sheet,
            "expected_size": (128, 128),
        },
        {
            "name": "warung_building.png",
            "desc": "Small Indonesian warung building with sign, lantern, jars",
            "fn": generate_warung_building,
            "expected_size": (96, 96),
        },
        {
            "name": "warung_interior.png",
            "desc": "Interior background with counter, stove, shelves, lantern, stools",
            "fn": generate_warung_interior,
            "expected_size": (640, 360),
        },
    ]

    print("\nGenerating sprites...")
    for target in targets:
        filepath = os.path.join(output_dir, target["name"])
        img = target["fn"]()

        # Validate dimensions
        assert img.size == target["expected_size"], (
            f"Size mismatch for {target['name']}: expected {target['expected_size']}, got {img.size}"
        )

        # Save as PNG with optimization
        img.save(filepath, format="PNG", optimize=True)
        file_size_bytes = os.path.getsize(filepath)

        print(f"  [OK] {target['name']}")
        print(f"       Resolution: {img.size[0]}x{img.size[1]} px")
        print(f"       File size : {file_size_bytes:,} bytes")
        print(f"       Path      : {filepath}")

    print("\nAll sprites generated successfully!")


if __name__ == "__main__":
    main()
