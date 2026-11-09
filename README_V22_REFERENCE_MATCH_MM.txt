SKETCH CHALLENGE V22 - REFERENCE-MATCHED GLASS MENU
===================================================
Scope: Main Menu and Level Selection only.

Changes:
- The home screen background uses an updated Kitchen photo composite.
- The home glass panel, logo, typography and buttons have been redesigned
  to better match the two user-approved glassmorphism concept images.
- The first three levels are playable; levels 4-6 remain Coming Soon.
- Level rows are clickable Controls with soft glass borders and fixed
  vertical spacing. No vertical PLAY text and no overlapping stage rows.
- Text and controls are live Godot nodes, NOT a flattened screenshot.
- No looping zoom/pan on the introduction.
- All existing Stage Complete interactions from V21 are preserved.

UNCHANGED from V21:
  Main.gd, Stage2.gd, Stage3.gd, DrawingCanvas.gd, AIConfig.gd,
  GameProgress.gd, StageCompleteOverlay.gd, audio, Stage3Assets.

Install:
1. Back up existing project.
2. Extract FULL ZIP to a new folder and import project.godot; or
3. Extract PATCH ZIP and copy GameMenu.gd + MenuAssets into res://.
4. Allow Godot to import the four V22 images, then press F5.
5. Check Main Menu, Play/Levels, Back to Home/Back to Game, and stage launch.

Note: Visual approximation of the provided concept reference.
Godot StyleBoxFlat does not perform real-time frosted backdrop blur.
The menu uses a pre-blurred source background and translucent live panels.
The game engine runtime was not available for execution in this environment.
