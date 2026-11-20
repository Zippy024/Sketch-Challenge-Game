# Kitchen Decoration Game — continue here

Repository: Zippy024/Sketch-Challenge-Game. Godot project, published on GitHub Pages:
https://zippy024.github.io/Sketch-Challenge-Game/

Communicate concisely in Burmese. The user wants work completed and published;
avoid repeated confirmation. Keep unrelated changes and user-uploaded recordings.

The user reverted the wide evolving Home/dropdown redesign from PR #60. Keep the
previous compact Home panel, original three language-choice cards, original
Language back-button placement and original intro. Do not restore the ten-stage
Home preview without a new request. Preserve the independent SVG result-card
check/cross fix: use TextureRects, not missing font glyphs.

Current Stage 3 design: two image questions, then eight Japanese component names.
Select the real 3D part directly; hover highlights its mesh, click/tap opens a
single contextual answer editor. Eight small numbered pointer guides with leader lines follow the meshes and
are clickable as an alternative to direct mesh selection. The numbered LEFT
checklist buttons open that same contextual editor, preserve drafts, and mirror
selection/highlighting. Full 360° drag,
orbit buttons, view presets and zoom are available. Eight parts: worktop, kitchen
panel, hood, drawer handles, sink, faucet, IH hob, drawers. Hiragana readings convert
to Kanji/Katakana candidates before individual grading. Layout questions show a
brief heading verdict. Components use an object-anchored ivory result card with
a mint top edge, green check/red cross, localized verdict and submitted Japanese
name. Correct answers include the matching hiragana reading; incorrect answers
never disclose the solution and return to editing after two seconds. Correct
cards fade and close after two seconds. Selecting a part cancels stale animations.

Latest visual reference: white cabinets/countertop, black IH, stainless recessed
sink and curved faucet, pale gray back panels/hood, light wooden floor. No person
inside the 3D model scene. No enclosing room walls, hard shadows, or spot glare.
The perspective camera centers and fits the complete floor and kitchen to each viewport;
soft studio reflections, satin metal and continuous stone improve the surfaces.
The user clarified that the KITCHEN belongs at the rear-left corner of the
original 5.0 × 3.42 m floor, while the whole 3D view remains centered. A single
KitchenInstallation transform moves all parts/details/contact shadow together;
anchors remain in kitchen-local coordinates and are transformed for projection.
Keep each part, anchor, leader offset and assessed index connected as before.
Do not shift the whole viewport to the top-left.
The reference plan stays in the LEFT column in all three sections; footer and
progress fit short/wide screens. Reference thumbnails open a zoomable/pannable overlay. Question text reveals progressively from the playback clock, using measured
speech windows and clause pauses in the nine recordings. Silent MP3 tails do
not delay the final text. Pause freezes text, Replay restarts it, and Myanmar
text is shaped before character visibility changes to keep layout stable.
The speaking meter follows playback inside the conversation bubble in all
implemented stages. There are no narration replay/pause buttons. Internal audio
pause/resume remains available for the game menu; keep header Home/menu controls.
Part 1/2 completion automatically shows a smooth section announcement, holds
the title long enough to read (1.25 seconds), then fades into the next question.
There is no Continue button. Narration starts after the announcement closes. Save schema v3 preserves other old answers and completed results, while
clearing the former waist-wall slot when migrating to the new handle question;
new attempts require all eight names. Preserve best stars,
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

Translation policy: Japanese dialogue is the source of truth. Stage 1 Myanmar
and English subtitles must explicitly include the living/dining area and kitchen.
The layout label requested by the user is အလေးချိန်ခံနံရံ. Existing uploaded audio
files have not been regenerated; translation corrections do not replace spoken
recordings. TTSMaker access from the managed session currently returns HTTP 403;
do not claim that newly synthesized recordings have been created.

Stage 1 reference hint: after the question finishes and the reference fades in,
briefly pulse the user's blue LDK boundary (not the red furniture rectangle).
Replay this five-cycle (4.2-second) hint whenever its enlarged reference popup opens. The
normalized polygon uses the same image transform for zoom/pan and resizing;
only a thin 1.2 px blue outline blinks at full strength, with no fill or glow.
Stage1Assets/reference-outline.gdshader temporarily hides the blue ink baked
into the source during each off phase, using nearby non-blue image samples;
otherwise the original static blue line makes a fading overlay imperceptible.
At rest the shader displays the original image unchanged. The original
marked image remains unchanged after the pulse. Keep Stage 2's
PS highlight behavior and all drawing/answer validation unchanged.

Stage 3 reference hints use the original plan and the user's marked kitchen
counter footprint, not the whole kitchen room. A thin 1.2 px rectangle pulses
for 2.5 seconds on thumbnails in all three parts and each enlarged opening; a
quiet thin outline remains after the pulse. No color fill or glow. Thumbnails
ignore input so clicks still reach ReferenceOpen; enlarged zoom/pan is retained.

Stage 3 sidebar is now conversation + a single Reference Plan card in all
parts. Part 3 places the eight clickable numbered entries beneath its image.
Do not restore Mission brief, its instruction paragraph, or Parts checklist
headings. Assessment #4 is now drawer handles (取っ手／とって), replacing the
removed half-height rear wall. Keep #1 counter, #2 kitchen panel, #3 hood,
#5 sink, #6 faucet, #7 IH and #8 drawer. Handles are real independently
pickable/highlightable geometry; all eight names are required.

Stage 3 close-up zoom: range 0.45–4.8 (default 3.15), about seven times the
normal view. Scroll zoom follows the point under the cursor; toolbar +/−
centers the selected part or kitchen worktop. Right/middle drag pans; left drag
still orbits 360°. Off-screen numbered guides are hidden rather than piled at
the viewport edges, and selecting an off-screen part from the left checklist
pans it into view. Presets restore the centered overview and clear pan; pose
restoration includes pan. Keep all physical mesh/anchor coordinates unchanged.

Solved Stage 3 parts: immediately hide their 3D numbered guide and leader line,
remove hover/selection, ignore mesh/pointer selection and disable the matching
left checklist button. Keep the verified Japanese answer visible in the left
list in teal. Solved entries cannot reopen an editor or change their saved
answer. Preserve the current two-second correct-result card before it closes.
Loaded solved flags hide/lock the same entries after reload, camera changes and
narration readiness changes; Retry restores fresh guides.

## Aqua Builder Home/loading/header (2026-11-20)
The user selected the centered Home menu with two progress tiles (best stars and saved session stage), plus the Aqua Builder loading/header mockup. Home is centered, original logo stays above it, Language back is upper left, all four menu actions remain. HomeProgress now renders the two tiles from real saved values. Welcome/subtitle/last-played labels have en/mm/jp translations. Original three-card language selection and level-selection structure are preserved.
AquaStyle supplies cached SVG pearl/turquoise surfaces and stage badge artwork. LevelReach keeps its original state/metadata and ten stage positions, now circular with a larger active shield and actual completion checks/locks. Header height is 80px. LoadingScreen and the exported browser shell use segmented progress, original logo, and matching aqua surfaces; browser file progress and startup/error handling remain unchanged.
The owner will upload two separately delivered PNG paintings: UIAssets/AquaHome.png and LoadingAssets/AquaBuilder.png. See AQUA_ASSETS.md. Optional ResourceLoader lookup falls back to the original images until upload, and CI selects the new browser loading picture when present. Do not bake mockup labels/UI into the paintings or replace the original logo.

### Aqua UI refinement / Designer Journey header (2026-11-20)
Supersedes the initial Aqua Builder header/loading styling above. User reported off-center button labels and disconnected stage links, then explicitly chose the Designer Journey cropped reference (wavy connected track, circular medals, current-stage flag; loading percentage pill with gold side lines). AquaStyle balances native Button icon reservation with equal right-side padding in normal/hover/pressed/disabled states and adjusts vertical padding to the drawn pill body. Main actions are bold; native text/icons/callbacks and translations remain.
LevelReach now draws full wavy connections behind the medals across their entire allocated spacing, retains ten stateful checkpoints, and puts the translated current-stage label in a flag over its gold numbered medal. Removed the repeated shield number and stub connectors. Browser and Godot loading now show the percentage pill, retaining real browser progress/error handling and the existing native timing.
User also requested aqua coloring for the logo and game interior. The original logo composition was recolored by image_gen, exported to transparent lossless WebP at LoadingAssets/KitchenLogo.webp, and is shared by all screens/browser. Workspace, cards, stage tabs and level-selection colors use pale aqua/icy blue; semantic correct/incorrect colors remain. The owner's newly uploaded AquaHome/AquaBuilder paintings and duplicate root uploads are preserved.

### Final glass-bubble stage reference (2026-11-20)
While the previous revision was building, the user selected a different final header reference: transparent-looking numbered stage bubbles on a smooth aqua wave, completed ticks/stars, current-stage aqua halo with small top chevron; language dropdown plus circular aqua Home/Menu with white icons. This supersedes the flag/pedestal design. LevelReach keeps all state/meta/ten checkpoints, now shows only two-digit numbers (01–10) and localized state tooltips; existing smoke expectations updated accordingly. Loading percentage pill/gold side lines, centered Home buttons and recolored logo/interior from PR70 remain. No new image upload needed; glass/bubble/circular-button resources are cached SVGs generated by AquaStyle. Native language popup behavior and original actions remain.
