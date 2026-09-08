"""Measure visible bounds/ground pivots without changing any generated image.
Requires Pillow and numpy in the offline art environment, not at game runtime.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'city-v2'
frames = {}
for path in sorted(ROOT.glob('*.png')):
    if path.stem == 'masonry':
        continue
    image = Image.open(path).convert('RGBA')
    alpha = np.asarray(image)[:, :, 3]
    yy, xx = np.where(alpha > 32)
    left, top = max(0, int(xx.min()) - 3), max(0, int(yy.min()) - 3)
    right = min(image.width, int(xx.max()) + 4)
    bottom = min(image.height, int(yy.max()) + 4)
    solid_y, solid_x = np.where(alpha > 160)
    ground_y = int(solid_y.max())
    pivot = [round(float(np.median(solid_x[solid_y >= ground_y - 4]))), ground_y]
    frames[path.stem] = {'region': [left, top, right - left, bottom - top], 'pivot': pivot}
(ROOT / 'regions.json').write_text(json.dumps(frames, indent=2) + '\n')
(ROOT / 'regions.gd').write_text('extends RefCounted\n\nconst FRAMES := ' + json.dumps(frames, indent=2) + '\n')
print('WF_CITY_ASSET_BOUNDS:', len(frames), 'transparent sprites; original PNGs unchanged')
