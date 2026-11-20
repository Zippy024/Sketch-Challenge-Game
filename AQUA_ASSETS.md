# Aqua Builder artwork upload

The centered Home menu, two progress tiles, segmented loading indicators and circular stage checkpoints are implemented in code. Original logo, language handling, save data and gameplay remain in place. The two standalone background paintings are supplied separately so the repository owner can upload them.

Upload the PNG files with these exact case-sensitive paths on `main`:

| File | Repository destination |
| --- | --- |
| `AquaHome.png` | `UIAssets/AquaHome.png` |
| `AquaBuilder.png` | `LoadingAssets/AquaBuilder.png` |

Extract the supplied `AquaBuilder-assets.zip`. In GitHub, open this repository's root, choose **Add file → Upload files**, and drag its `UIAssets` and `LoadingAssets` folders into the upload area. Check that the paths above are shown and commit to `main`. Alternatively upload each PNG from inside its corresponding existing folder. Do not upload the ZIP itself or the design mockups as game backgrounds. Keep `LoadingAssets/KitchenLogo.webp` unchanged.

The next normal Pages workflow imports the PNGs and uses them automatically, including the browser's download screen. Until upload, the new UI remains usable with the original background paintings. No source edit or asset rename is required after upload.

The artwork contains no logo, buttons, progress numbers or text. Those are real localized controls overlaid by Godot. Header badges and loading segments are drawn by code and require no additional PNGs.

Home follows the user's final attached centered design: total best stars across the three currently playable stages (maximum nine) and saved session stage. It does not use the later journal mockup. Stage 04–10 remain unavailable as before. Existing Start Game, Continue, Retry, best scores, Japanese answers and narration behavior are unchanged.
