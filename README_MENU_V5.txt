SKETCH CHALLENGE — PHOTO MENU V5 (GODOT 4.7.2)
==================================================
Based on the user's latest V4 source project and storyboard.

New UI features
- Kitchen photo hero (MenuAssets/KitchenHero.jpg), real Godot TextureRect.
- Main menu uses interactive START GAME, HOW TO PLAY, SETTINGS, EXIT (desktop only) buttons.
- Level selector uses SIX horizontal image-enhanced rows. Stage 1/2 launch directly.
- Stage 2 remains LOCKED until Stage 1 drawing answer validates as correct.
- MENU/LEVELS from gameplay opens a PAUSE OVERLAY; BACK TO GAME restores drawing/answer.
- Choosing a level intentionally RESTARTS that level.
- Language buttons Japanese/Myanmar use existing bundled WebBilingualTheme.
- SETTINGS has volume control and two-step RESET LEVEL PROGRESS option for testing.
- Existing Stage1/Stage2 game logic, audio, drawing, question checking untouched except the shared GameProgress reset helper.

How to run
1. Extract this ZIP to NEW directory (do not overwrite a known-good Godot project).
2. Open project.godot using Godot 4.7.2.
3. Run the whole project (F5). Do not start via Main.tscn (F6) when you want the menu.
4. START GAME -> Level 01 should go straight into the dialogue and drawing.
5. Draw, press LEVELS, then BACK TO GAME; your exact sketch should be preserved.
6. LEVELS -> Level 01 should restart stage 1 and clear the current sketch.
7. Stage 02 remains locked until successful Stage 01 check.
8. For an old saved game with Level 2 previously unlocked, use Home -> SETTINGS -> RESET LEVEL PROGRESS -> CONFIRM RESET.

Website deployment
- Do NOT put API keys in GitHub/HTML/Godot Web.
- In an existing GitHub clone, preserve .github/workflows/main.yml while replacing Godot sources.
- Check Main.gd, Stage2.gd, GameMenu.gd, GameProgress.gd, MenuAssets, Font, WebBilingualTheme.tres, project.godot, scenes and all MP3s.
- Commit/Push and run deployment. Test fresh in a private browser session.

Images
- MenuAssets/KitchenHero.jpg is a clean kitchen-photo crop from a generated illustrative storyboard.
- MenuAssets/Level*.png are small thumbnail crops from the same illustrative source, and are decorative only.
- The game drawing plan remains reference_sketch.png from the original project.

Limitations
- Stages 3-6 are previews/coming-soon, not functioning game stages.
- Existing Stage 2 is the real Pipe Shaft Q&A; the example storyboard's 3D Kitchen screens illustrate future-stage ideas.
- Source paths/static assets checked, but no Godot executable is available in this environment to run/verify compilation or browser render.
