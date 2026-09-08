"""Validate rendered silhouettes and mixed sound files, not just their existence."""
from pathlib import Path
import array
import hashlib
import json
import wave
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
failures = []
count = 0
manifest=json.loads((ROOT/"assets/characters/world-motion/manifest.json").read_text())
project=ROOT.parents[1]
profile=manifest["profile"]
stage=project/profile["source"].removeprefix("res://")
if hashlib.sha256(stage.read_bytes()).hexdigest()!=profile["sha256"]:
    failures.append("The shared scene renderer changed after this bake")
for source,digest in manifest.get("sources",{}).items():
    if hashlib.sha256((project/source.removeprefix("res://")).read_bytes()).hexdigest()!=digest:
        failures.append(f"Source changed after bake: {source}")
sheets=[]
for kind, actor in manifest["actors"].items():
    for action,spec in actor["clips"].items():
        sheets.append((project/spec["file"].removeprefix("res://"),spec))
if len(sheets)!=28: failures.append(f"expected 28 active sheets, found {len(sheets)}")
for path,spec in sheets:
    im = Image.open(path)
    cell,frames=int(spec["cell"]),int(spec["frames"])
    if hashlib.sha256(path.read_bytes()).hexdigest()!=spec["sha256"]:
        failures.append(f"{path.name}: differs from the verified bake")
    if im.mode!="RGBA": failures.append(f"{path.name}: missing real alpha")
    if im.size != (cell*frames,cell*8):
        failures.append(f"{path.name}: dimensions {im.size}")
        continue
    for direction in range(8):
        unique = set()
        for frame in range(frames):
            image = im.crop((frame*cell,direction*cell,(frame+1)*cell,(direction+1)*cell))
            bounds = image.getbbox()
            count += 1
            if not bounds or bounds[0]<=0 or bounds[1]<=0 or bounds[2]>=cell or bounds[3]>=cell:
                failures.append(f"{path.name} {direction}/{frame}: clipped or missing silhouette {bounds}")
            unique.add(hashlib.sha256(image.tobytes()).digest())
        if path.stem.endswith(("-walk","-run","-idle")) and len(unique)!=frames:
            failures.append(f"{path.name}: repeated walk poses in direction {direction}")
audio = sorted((ROOT/"assets/impact-audio").glob("*.wav"))
if len(audio)!=36:
    failures.append(f"expected 36 sound variants, found {len(audio)}")
hashes = set()
for path in audio:
    with wave.open(str(path),"rb") as wav:
        if (wav.getnchannels(),wav.getframerate(),wav.getsampwidth())!=(2,48000,2):
            failures.append(f"{path.name}: incorrect audio format")
        pcm = wav.readframes(wav.getnframes())
        samples = array.array("h",pcm)
        peak = max(map(abs,samples))/32768
        if not 0.1<peak<0.9:
            failures.append(f"{path.name}: silent or insufficient headroom {peak}")
        # Fast contact: a positive onset in the first 12 milliseconds.
        if max(map(abs,samples[:1152]))<150:
            failures.append(f"{path.name}: slow/missing onset")
        hashes.add(hashlib.sha256(pcm).digest())
if len(hashes)!=len(audio): failures.append("audio variants repeat identical samples")
report = f"WF_PERFORMANCE_ASSETS_OK: {count} complete transparent frames; full idle/walk/run sequences in 8 directions; shared render profile and file hashes; 36 distinct stereo sounds with onset and headroom"
if failures:
    print("\n".join(failures)); raise SystemExit(1)
print(report)
(ROOT/"preview/performance-assets-verification.log").write_text(report+"\n")
