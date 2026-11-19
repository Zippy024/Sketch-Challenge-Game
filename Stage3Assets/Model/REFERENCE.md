# Stage 3: directly selectable kitchen model

Real Godot meshes follow the supplied video, elevation, and latest white-kitchen
reference: 2573 mm worktop, approximately 850 mm finished height, 750/750/1050 mm
front bays, 900 mm full-height support, stainless sink and curved mixer, white
cabinet fronts, black IH hob, pale gray back panels/hood and a light wooden floor.
No person is included in the model scene. Cabinet fronts, the hood and hob have
small physical chamfers. Faucet curves have finer segments, the hood has control
and grille details, and the basin includes strainer detail. A faint contact patch
anchors the cabinet to the oak floor; directional shadows stay disabled. Stone
uses subtle non-periodic grain rather than visible wave bands.
Soft studio reflection cards define the metal without enclosing room geometry.
The original 5.0 × 3.42 m floor retains its position and material. The complete
kitchen is installed near the floor’s rear-left corner using a single parent
transform, including unpickable details and its contact shadow. Numbered anchors
retain their kitchen-local coordinates and pointer offsets, and are transformed
with the installation for projection. The perspective camera centers and fits
the actual floor and kitchen bounds across short/wide/tall viewports;
render-target limits preserve aspect.

Eight assessed parts have independent collision and highlight groups: worktop,
kitchen panel, range hood, drawer handles, sink, faucet, IH hob and drawers.
The former assessed half-height rear wall is removed. Part 4 now groups all
actual drawer handles, with a pointer anchored to the large sink-side handle
and slightly forgiving hitboxes kept clear of the drawer faces.
Hover highlights the actual mesh. Clicking/tapping a visible part opens one
contextual Japanese answer editor. Eight compact numbered pointer guides and thin leader lines help locate every
part, follow camera movement and accept clicks alongside direct mesh selection.
The left numbered checklist also opens the same part editor, with the same saved
draft, selected highlight, conversion and grading.
Dragging or the orbit buttons supports a full 360° rotation; front/rear/perspective
presets and zoom remain available. The rear view shows the cabinet backing
without a separate waist wall.

Hiragana conversion candidates depend only on the typed reading, not the target.
Japanese synonyms, full-width/half-width forms, IH and proper okurigana are
accepted. Empty or unconverted readings do not add mistakes. Correct answers lock
and confirm in an object-anchored ivory card for two seconds, with a mint top edge,
green check/red cross and submitted Japanese name. Correct cards show the matching
hiragana reading; incorrect cards never reveal the solution and return to editing.
Drafts and solved flags persist. Reference plans stay on the left and open an enlarged, zoomable/pannable viewer.
Question text reveals with recorded speech windows and pauses, completes before
the silent audio tail. Internal pause/replay APIs remain for session/menu control
and checks, while narration buttons are removed from the stage interface. The
playback meter animates inside the conversation bubble in Stages 1–3; full text
remains readable after narration.
Section announcements enter smoothly, hold for reading, then fade automatically
before the next recording begins. No Continue button is required.

Two layout questions plus
eight names make ten challenge checks. Retry resets only the current attempt.

Version 3 extends old five-answer saves and keeps other drafts/verified names,
but clears the former wall answer/solved flag at slot 4 before asking for handles.
Previously completed attempts retain completion and best scores; a fresh attempt
requires all eight names. Supersampling and on-demand viewport redraws keep the
model clear without continuously rendering a static scene.

The left sidebar contains the conversation and one Reference Plan card only.
Part 3 adds eight numbered answer buttons below the plan; Mission brief, its
paragraph and Parts checklist headings are removed. Reference highlights,
click-to-enlarge and enlarged zoom/pan remain.

Close-up zoom extends to 0.45 (default 3.15), with wheel zoom anchored under
the cursor and toolbar zoom centered on the selected part/worktop. Right or
middle drag pans without changing orbit; left drag keeps 360° rotation. Presets
reset pan/zoom. Off-screen guides hide, and checklist selection brings an
off-screen part into view. Meshes and numbered anchors never move.

A correct answer removes that part's numbered guide/leader and disables further
answer interaction via its mesh, pointer or checklist entry. The verified name
remains visible in the left checklist. Its current correct-result card still
finishes normally. Solved flags persist across reload and camera changes; a
fresh Retry restores all eight guides and writable answers.
