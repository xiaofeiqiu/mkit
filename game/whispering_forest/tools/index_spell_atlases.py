"""Index generated alpha without modifying, masking or resampling the PNGs."""
from pathlib import Path
import json
from PIL import Image

folder = Path(__file__).resolve().parents[1] / "assets/combat-vfx"
path = folder / "regions.json"
metadata = json.loads(path.read_text())
for name, columns, rows in [
    ("flame-burst-v4", 4, 4),
    ("tornado-loop-v3", 4, 4),
    ("meteor-variants-v5", 3, 2),
    ("meteor-puffs-v1", 2, 2),
]:
    image = Image.open(folder / f"{name}.png")
    assert image.mode == "RGBA", f"{name}: transparent RGBA required"
    alpha = image.getchannel("A")
    regions = []
    for row in range(rows):
        for col in range(columns):
            left, top = round(col * image.width / columns), round(row * image.height / rows)
            right, bottom = round((col + 1) * image.width / columns), round((row + 1) * image.height / rows)
            box = alpha.crop((left, top, right, bottom)).point(lambda a: 255 if a > 40 else 0).getbbox()
            assert box, f"{name}: empty cell {col}, {row}"
            x0, y0 = max(0, box[0]-2), max(0, box[1]-2)
            x1, y1 = min(right-left, box[2]+2), min(bottom-top, box[3]+2)
            regions.append([left+x0, top+y0, x1-x0, y1-y0])
    metadata[name] = {"size": list(image.size), "regions": regions}
path.write_text(json.dumps(metadata, indent=2) + "\n")
print("Indexed fire, wind, and six grey meteor variants; original PNG alpha preserved.")
