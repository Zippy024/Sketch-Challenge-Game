SKETCH CHALLENGE V19 – GLASS / TEAL MENU UPDATE
===========================================

Included changes
- Main Menu: Green–teal glass card over kitchen photo, redesigned logo, working real buttons, animation.
- Level Select: Blurred kitchen background, glass rows for Stage 1–6, live hover/press, no fake screenshot controls.
- Active: Stage 1, Stage 2, Stage 3; Stage 4–6 remain COMING SOON.
- All original menu functions including language, back-to-game resume, profile, progress, achievements, guide and settings remain wired.
- V18 completion animations remain in place.
- Godot gameplay scripts Main.gd, Stage2.gd, Stage3.gd and StageCompleteOverlay.gd are NOT edited.
- Existing font files, original branding and game art are included in FULL archive.

What changed:
  GameMenu.gd
  MenuAssets/GlassKitchenHome.jpg
  MenuAssets/GlassKitchenLevels.jpg
  MenuAssets/GlassKitchenLogo.png
  MenuAssets/GlassPlay.png, GlassBook.png, GlassSettings.png
  MenuAssets/GlassUser.png, GlassProgress.png, GlassTrophy.png
  MenuAssets/GlassHome.png, GlassArrow.png, GlassBack.png, GlassLock.png
  MenuAssets/GlassStage1.png, GlassStage2.png, GlassStage3.png
  README_V19_GLASS_UI_MM.txt

HOW TO INSTALL
1. Back up current Godot project.
2. Quit Godot before replacing files.
3. FULL ZIP: unzip then import Sketch_Challenge_Game/project.godot in Godot.
   PATCH ZIP: unzip at project res:// root; replace GameMenu.gd and add MenuAssets/Glass* files.
4. Let Godot import textures, then F5.
5. Test Home, Start Game > Level Menu, language buttons, Settings, Pause > Home > Back to Game.
6. Complete Stages to verify existing V18 celebration overlay.

NOTE:
- This is a real Godot Control-based implementation of the chosen second (glassmorphism) designs, not a pixel-perfect rendering of a concept illustration.
- Glass effect is made with safe translucent panels and pre-blurred kitchen background images; no expensive screen capture or shader is required.
- The game scenes have NOT been redesigned; that would be a separate change after reviewing a proposed in-game style.
- Godot Editor/runtime itself is not available in this environment. ZIP integrity, image signatures, resource paths and unchanged gameplay files were checked; runtime UI testing still needs F5 in Godot.
