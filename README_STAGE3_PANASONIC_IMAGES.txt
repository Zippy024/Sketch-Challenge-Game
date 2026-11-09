Stage 3 Kitchen Selection - image source / layout note

Source reference:
https://sumai.panasonic.jp/kitchen/plan/
https://sumai.panasonic.jp/kitchen/

The included q1_*.png and q2_*.png assets are the existing images from the previous project, NOT downloaded official full-resolution Panasonic product images. They were obtained from the supplied screenshots and their visual detail is intrinsically limited. This update improves how they are displayed and removes the distracting blue keyboard focus outline on choice cards.

To replace with Panasonic's official source images when you have permission and original image files:
- Open res://Stage3Assets/ in your project.
- Replace q1_1.png, q1_2.png, q1_3.png, q1_4.png, q1_5.png with appropriately matched layouts (I, L, face-to-face, II, island).
- Replace q2_1.png, q2_2.png, q2_3.png, q2_4.png with appropriate variants (full-flat, structural wall, float, round access).
- Keep the exact filenames to avoid code changes; use clean sRGB PNGs, preferably source illustrations >= 800x550 pixels.
- Let Godot finish importing before F5.

No Stage 1, Stage 2, AI, or menu code was changed.
