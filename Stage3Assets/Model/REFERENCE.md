# Stage 3: numbered kitchen model

The model is constructed from actual Godot 3D meshes using the supplied
`Recording 2026-11-13 111914.mp4` and elevation as visual references. It uses a
2573 mm worktop, approximately 850 mm finished height, 750/750/1050 mm cabinet
bays, a 900 mm hood/support area and approximately 2400 mm total support height.
The elevation and video guide the proportions; this is an educational rebuild.

The eight fixed assessed parts keep their labels when the 3D model rotates:
1 counter/worktop, 2 kitchen board, 3 range hood, 4 waist-height rear wall,
5 sink, 6 faucet, 7 IH cooktop, 8 upper drawer. The oak floor and surrounding
cabinetry provide the visual context.
All are meshes rather than a flattened substitute image. Number markers track
3D positions as the camera rotates. The rear view reveals the waist wall.

Students type Japanese names. `JapaneseParts.gd` accepts relevant Japanese
synonyms and normalizes spacing, Hiragana and half-width Katakana. It does not
accept English names or score a mere click as a correct answer. Empty entries
do not add mistakes. Correct entries lock; drafts and individual solved flags
persist in the existing save file. Legacy sequential-selection saves migrate
without losing already verified progress. Retry resets only the current attempt.

The full model workspace uses a supersampled viewport with on-demand redraws,
subtle greige cabinet grain, a curved mixer and a rounded stainless basin.
Hovering or clicking a number opens one contextual answer editor; dragging or
closing restores the unobstructed view. Students enter a Hiragana reading,
choose a Kanji/Katakana candidate based only on that reading, then submit.
Conversions are independent of the assessed part. Correct answers briefly
confirm and dismiss the editor; each question starts without an old verdict.

## Reference-matching showroom rebuild (13 November 2026)

The procedural kitchen uses a light oak plank floor, off-white corner walls, grey stone back panel and cooking bay, warm white slab counter with recessed metallic sink, curved silver mixer, black IH rings, oven controls, matte-grey range hood and satin off-white black-handled cabinets. The model intentionally contains **no person**. The room walls hide only when viewed from behind, so 360-degree drag/orbit and zoom remain possible; all eight fixed part markers and Japanese answer bindings remain active.

This reconstruction is an approximation of the supplied screenshot, not a photogrammetric scan or a byte-for-byte import of the supplied GLB. The interactive Godot meshes are kept instead of replacing assessable parts with a single opaque GLB.
