#!/Users/jmbrown/.claude/jobs/2d5a61e0/tmp/venv/bin/python
"""Assemble JPEG frames into a GIF (480 px wide, ~3 fps as captured)."""
import sys, glob, os
from PIL import Image
frames_dir, out = sys.argv[1], sys.argv[2]
files = sorted(glob.glob(os.path.join(frames_dir, "*.jpg")))
if not files: sys.exit("no frames")
imgs = []
for f in files:
    im = Image.open(f).convert("RGB")
    w, h = im.size; nw = 480; nh = int(h * nw / w)
    imgs.append(im.resize((nw, nh), Image.LANCZOS).quantize(colors=128, method=Image.MEDIANCUT))
imgs[0].save(out, save_all=True, append_images=imgs[1:], duration=330, loop=0, optimize=True)
print(out, len(imgs), "frames", os.path.getsize(out) // 1024, "KB")
