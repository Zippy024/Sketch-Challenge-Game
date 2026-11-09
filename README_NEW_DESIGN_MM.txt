KITCHEN DECORATION GAME - DESKTOP UI VERSION
============================================
Based on your own uploaded Godot project zip.

OPEN IN GODOT
1. Extract the new ZIP.
2. Open Godot 4.7.2 and choose Import.
3. Select KitchenDecorationGame/project.godot, then Run (F6/F5 as appropriate).

FLOW
Loading -> Language (Japanese or Myanmar) -> Main Menu -> Select Level -> Game.
The English dropdown option is deliberately disabled until English gameplay language is implemented.
Stage 01 LDK Drawing / Stage 02 Pipe Shaft Q&A / Stage 03 S-Class Kitchen Selection remain the uploaded originals.
Stages 04-06 remain locked (Coming Soon).

UPDATED / NEW
- GameMenu.gd: loading, language, home and six-stage card selection UI, settings/progress links preserved.
- Branding/BlueprintPencilGameLogo.png: original blueprint + pencil style graphic (no chef hat).
- Branding/BlueprintPencilIcon.png: new browser/application icon.
- MenuAssets/BlueStudioBackdrop.jpg: blue-tinted blurred stage backdrop.
- MenuAssets/Intro3DKitchenArt.png: decorative isometric kitchen drawing.
- MenuAssets/BlueShowroomPlatform.png: glowing cyan stage platform.
- Branding/SketchChallengeWebShell.html: matching loading screen for Web export.
- project.godot: application title, boot splash and icon.
- WebBilingualTheme.tres: system font fallback (see below).

UNMODIFIED GAMEPLAY
- Main.gd, DrawingCanvas.gd, main.tscn
- Stage2.gd, stage_2.tscn
- Stage3.gd, stage_3.tscn
- GameProgress.gd, MenuExtras.gd
- All original stage images, audio, answer checking, dialogues and saving.

LANGUAGE FONT NOTE
To keep the ZIP portable without redistributing font binaries, the provided Theme uses available OS font fallbacks.
For the *exact* Myanmar/Japanese font appearance on your Windows machine, copy your original "Font" folder from
Sketch_Challenge_Levels_Menu_Godot(2).zip into this project and restore/adjust the theme if necessary.
The source fonts themselves are not redistributed in this edited ZIP.

TEST NOTE
Structural checks and the ZIP checksum test passed. The Godot binary was unavailable in this workspace, so
there has not been a live engine render or input test of the new menus. If the Godot editor reports an error,
please send the error text/screenshot so the exact line can be corrected.
