SKETCH CHALLENGE V21 - MENU LAYOUT & READABILITY FIX

Changes to V20:
- GameMenu.gd only: Level Selection stage row layout rebuilt to avoid
  Stage 1-3 cards overlapping and vertical PLAY/RESTART text.
- BACK TO HOME/BACK TO GAME buttons no longer stretch to header height.
- Improved level row contrast, panel opacity, text sizes, and menu readability.
- Keeps the existing static kitchen background; no intro zoom motion.
- All stage buttons still open their original scenes (1, 2, 3).
- Levels 4, 5 and 6 remain COMING SOON.
- No changes to Stage 1 / Stage 2 / Stage 3 / Gemini AI / audio scripts.

Patch installation:
1) Back up your current Godot Project.
2) Close Godot.
3) Replace res://GameMenu.gd with the GameMenu.gd in this patch.
4) Reopen Godot and test F5 > Start Game > Levels.
5) While in a stage, open Levels and test BACK TO GAME.

Notes:
- UI uses Godot Controls, not a flattened screenshot.
- Headless/runtime Godot test was not available in this environment.
- Check display at your normal 1440x810 window and browser resolution
  before uploading to GitHub Pages.
