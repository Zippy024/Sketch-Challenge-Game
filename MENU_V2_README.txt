SKETCH CHALLENGE — WARM UI + DIRECT LEVEL LAUNCH
================================================
Godot 4.7.2 desktop / GitHub Pages Web source project.

WHAT CHANGED
- Rebuilt GameMenu.gd home screen using warm cream, white, forest/sage green and gold.
  Existing reference_sketch.png is used for the preview card; no new external image is needed.
- Replaced the 3-column square level grid with SIX full-width horizontal level rows.
  Level 1 is playable, Level 2 unlocks after completing Level 1, Levels 3-6 are previews.
- Selecting Level 1 now loads the actual drawing game DIRECTLY. The extra
  "START LEVEL 1" screen is skipped when you enter from Level Select.
- Selecting unlocked Level 2 goes directly to Stage 2 (as before).
- Standalone F6 of main.tscn still shows its existing START LEVEL 1 intro;
  this is intentional, so the scene can be tested in isolation.
- Preserved the proven Japanese/Myanmar WebBilingualTheme and font assets.
- Also fixed type inference and tab-versus-space indentation issues in the bundled scripts.
- Audio, drawing, reference reveal after audio, answer checking, Stage 2 progression,
  level save data, and MENU navigation are unchanged.

HOW TO TEST
1. Extract this ZIP into a NEW folder and open its project.godot in Godot 4.7.2.
2. Press F5 (Run Project; NOT F6 on main.tscn).
3. On the home screen press START GAME. The Level Select menu shows horizontal rows.
4. Click anywhere in Level 01 row. The drawing game should open immediately,
   with customer audio and subtitle animation and WITHOUT a second START button.
5. Check the Japanese and Myanmar controls; finish Level 1 and confirm Level 2 unlocks.
6. Test MENU return and Level 2 (PS Q&A). Test audio on Web after deployment.

GITHUB PAGES
- Your .github/workflows/main.yml belongs to the existing GitHub repository;
  do NOT delete it when copying source files from this ZIP.
- Copy the project CONTENTS (project.godot at repository root), commit, push,
  and check the newest GitHub Actions deploy before opening the website.

WEB AUDIO
Web browsers limit audio autoplay. A click on START GAME and Level 01 is a
user interaction, which usually unlocks Web audio; final behavior must be tested
in the target browser. If audio is blocked, subtitle/replay behavior may differ.

API KEY
Do NOT place any API key inside this public Godot Web project or GitHub.
Use a secure backend when adding online AI later.

LIMITATION
These sources were inspected and patched, but the Godot Engine is not installed
in this execution environment, so native Godot or browser execution was not
performed here. Verify the package using F5 and the website before replacing a
known-good deployment.
