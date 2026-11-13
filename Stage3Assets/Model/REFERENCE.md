# Stage 3: numbered kitchen model

The model is constructed from actual Godot 3D meshes using the supplied
`Recording 2026-11-13 111914.mp4` and elevation as visual references. It uses a
2573 mm worktop, approximately 850 mm finished height, 750/750/1050 mm cabinet
bays, a 900 mm hood/support area and approximately 2400 mm total support height.
The elevation and video guide the proportions; this is an educational rebuild.

The five fixed assessed parts are counter/worktop, kitchen board (the panel
between hob and hood), range hood, waist-height rear wall and sink. The hob,
mixer faucet, drawers and oak floor provide the surrounding visual context.
All are meshes rather than a flattened substitute image. Number markers track
3D positions as the camera rotates. The rear view reveals the waist wall.

Students type Japanese names. `JapaneseParts.gd` accepts relevant Japanese
synonyms and normalizes spacing, Hiragana and half-width Katakana. It does not
accept English names or score a mere click as a correct answer. Empty entries
do not add mistakes. Correct entries lock; drafts and individual solved flags
persist in the existing save file. Legacy sequential-selection saves migrate
without losing already verified progress. Retry resets only the current attempt.
