#!/Users/jmbrown/.claude/jobs/2d5a61e0/tmp/venv/bin/python
"""Halve a GIF's frame rate and colours: shrink.py in.gif out.gif [keep_every]"""
import sys
from PIL import Image, ImageSequence
src, dst = sys.argv[1], sys.argv[2]
keep = int(sys.argv[3]) if len(sys.argv) > 3 else 2
im = Image.open(src)
frames = [f.convert("RGB") for i, f in enumerate(ImageSequence.Iterator(im)) if i % keep == 0]
dur = im.info.get("duration", 330) * keep
q = [f.quantize(colors=96, method=Image.MEDIANCUT) for f in frames]
q[0].save(dst, save_all=True, append_images=q[1:], duration=dur, loop=0, optimize=True)
import os; print(dst, len(q), "frames", os.path.getsize(dst) // 1024, "KB")
