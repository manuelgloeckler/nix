---
name: image-preview
description: Show images (Matplotlib plots, screenshots, rendered figures, GIFs) in a sized Herdr pane instead of dumping escape codes into agent output. Use whenever you generate or need to inspect an image file.
---

# Image preview

Inside Herdr (`HERDR_ENV=1`) use the helper; never print image escape sequences into your own output.

```bash
herdr-image-pane plot.png        # one image
herdr-image-pane fig/*.png       # batch -> one montage grid
```

- Reuses one pane named `images` per tab; creates it on first use.
- Fits the image to that pane's current cell size and re-fits on the next call after a resize.
- Batches become a grid (up to 4 columns) built with ImageMagick `montage` under `~/.cache/herdr-image-pane/`.
- Prints the pane ID and rendered size; mention that pane to the user.

Renderer is `chafa -f kitty`. Do **not** use `kitten icat --place`/`--fit` inside Herdr: it needs the terminal's cell pixel size, and Herdr does not answer that query (`Terminal does not support reporting screen sizes in pixels`).

Requirements: `chafa` (plus ImageMagick for batches) and `python3`. Hosts synced with `dotsync` link the helper to `~/.local/bin/herdr-image-pane`; use that path when it is not on `PATH`.

Outside Herdr, `chafa -f kitty -s 80x40 path.png` on a real terminal, or hand the path to the user.
