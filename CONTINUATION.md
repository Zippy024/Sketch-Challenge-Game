# Kitchen Decoration Game — continue here

Repository: Zippy024/Sketch-Challenge-Game. Godot project, published on GitHub Pages:
https://zippy024.github.io/Sketch-Challenge-Game/

Communicate concisely in Burmese. The user wants work completed and published;
avoid repeated confirmation. Keep unrelated changes and user-uploaded recordings.

Current Stage 3 design: two image questions, then eight Japanese component names.
Select the real 3D part directly; hover highlights its mesh, click/tap opens a
single contextual answer editor. No floating numbered buttons. Full 360° drag,
orbit buttons, view presets and zoom are available. Eight parts: worktop, kitchen
panel, hood, waist wall, sink, faucet, IH hob, drawers. Hiragana readings convert
to Kanji/Katakana candidates before individual grading. Correct feedback expires.

Latest visual reference: white cabinets/countertop, black IH, stainless recessed
sink and curved faucet, pale gray back panels/hood, light wooden floor. No person
inside the 3D model scene. No enclosing room walls, hard shadows, or spot glare.
The reference plan stays in the LEFT column in all three sections; footer and
progress fit short/wide screens. Narration starts after the section transition
and subtitle layout, with a modest readable subtitle lead. Save schema v2 preserves old five-answer drafts and
completed results; new attempts require all eight names. Preserve best stars,
Retry, recorded speech, and Start Game → Level Select → Play.

Read Stage3Assets/Model/REFERENCE.md, Stage3.gd, GameProgress.gd, KitchenModel.gd,
JapaneseParts.gd and PartAnswerPopover.gd before changing behavior. Regression
scripts in Tests cover direct physics picking, 360° input, three languages,
session migration/Retry, completion timing, and nine Stage 3 recordings.
The deployment workflow runs these checks and publishes a commit-tagged bundle;
verify public build.json before reporting a deployment as live.

In the previous managed environment the checkout was
/workspace/work/stage3-overlay-flow (branch direct-eight-parts). If absent, use
GitHub main and check recent PRs/Actions before repeating any work. The user asked
for this handoff so a new chat can continue without rebuilding completed changes.
