SKETCH CHALLENGE — STAGE 3 + LEVEL ACCESS UPDATE

Changes from the supplied ZIP:
- Level menu now enables Stage 1, Stage 2 and Stage 3 independently.
- Stage 4–6 remain COMING SOON, since they have no gameplay scenes.
- Stage 3 added as new scene and script in matching Stage 1/2 colors/layout.
- Stage 3 Part 1: two illustration-selection questions (S-Class type -> facing, back wall -> load-bearing wall), retry until correct.
- Stage 3 Part 2: five labelled kitchen components are identified by clicking interactive regions in a schematic drawing; retry until correct.
- The option graphics for Part 1 are cropped from the reference screenshots supplied in the conversation.
- No actual 3D model was provided; Part 2 intentionally uses a schematic 2D interactive diagram, not a true 3D model. Swap with supplied 3D kitchen assets later if needed.
- Main.gd, Stage2.gd, DrawingCanvas.gd, AIConfig.gd, Cloudflare Worker, audio and original menu appearance are unchanged.

INSTALLATION
1. Back up your project.
2. Patch ZIP: copy GameMenu.gd, GameProgress.gd, Stage3.gd, stage_3.tscn and Stage3Assets folder to res://.
3. Or extract complete ZIP and import the contained folder/project.godot.
4. Open in Godot 4.7.2; run F5; from Select Level test Stage 1, Stage 2 and Stage 3.
5. Stage 4–6 remain non-clickable until real scenes exist.

TESTS TO DO IN GODOT
- Stage 1 and Stage 2 launch without previously completing an earlier stage.
- Stage 3 Q1 selecting 対面 proceeds; wrong selection stays on Q1.
- Stage 3 Q2 selecting 耐力壁 proceeds; wrong selection stays on Q2.
- Stage 3 Part 2 click named parts in this order: countertop, kitchen board, hood, half wall, other fixture.
- Levels -> Back to Game resumes at same Part 1/Part 2 state.

Godot engine execution was not available in this environment; test in Editor prior to GitHub publishing.
