Sketch Challenge - Stage 3 Anti-Aliasing Card Fix
====================================================
This package replaces Stage 3 illustration PNG files and adjusts their
sampling in Stage3.gd. Stage 1 / Stage 2 / AI / audio / menu untouched.

Why: A 1448 x 1086 illustration was being minified to about 200px inside
Godot using a linear filter without mipmaps, producing dotted/jagged lines.

Change:
- Replace Stage3Assets/q1_1..5.png, q2_1..4.png with 520 x 370
  antialiased card-ready PNGs. These retain each option illustration.
- Generate and cache mipmapped ImageTexture at runtime in Stage3.gd.
- Display with TEXTURE_FILTER_LINEAR_WITH_MIPMAPS.
- No changes to answer indices / stage progression / Stage 1 or 2.

Installation: Close Godot, back up project, extract the PATCH zip into
project root (where project.godot exists) and overwrite. Reopen Godot F5.
If an old cached image appears, close Godot, delete ONLY the .godot cache
folder, and reopen (Godot rebuilds the cache).

Caveat: These are antialiased card-ready versions of the existing generated
illustrations, NOT authentic Panasonic high-resolution product drawings.
Actual originals would be needed to guarantee technical product accuracy.
Godot Engine execution was not available in this environment.
