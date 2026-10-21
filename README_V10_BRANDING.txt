SKETCH CHALLENGE — VERSION 10 BRANDING PATCH
============================================

This PATCH must be copied into your existing, WORKING Version 9 Godot project.
It intentionally does not include your existing game/audio/font assets or scenes.
Keep your Font folder and ALL existing game files as they are.

CHANGES
1. In-game top-left SC badge is now the new house/floorplan/pencil logo.
2. Project Settings -> Application -> Config -> Icon points to the same logo.
3. Web export preset -> Html -> Export Icon is ON, so Godot exports index.icon.png.
4. Web export -> Html -> Custom Html Shell points to the included HTML file.
5. Web loading screen shows Sketch Challenge branding, game-specific kitchen backdrop,
   and a progress bar. It no longer displays the stock Godot loading logo.
6. Desktop boot splash is also branded.
7. No changes to level logic, audio, drawing, AI, or bilingual Font/Theme system.

INSTALL
1. Back up the working Godot project folder first.
2. Unzip this package. Copy the contents INTO the root of your working V9 project:
     Branding/               (entire folder)
     GameMenu.gd             (replace)
     project.godot           (replace)
     export_presets.cfg      (replace)
     SketchChallengeIcon.png (replace, optional legacy consistency)
3. Verify your project still has Font/, WebBilingualTheme.tres, Main.gd, Stage2.gd,
   GameProgress.gd, GameMenu.tscn, main.tscn, stage_2.tscn, MenuAssets/.
4. Open the project in Godot 4.7.2 and press F5. Verify the new branded top-bar icon.
5. Open Project -> Export -> Web and confirm:
     Html > Export Icon          checked
     Html > Custom Html Shell    res://Branding/SketchChallengeWebShell.html
6. Upload/commit/push ALL CHANGED FILES plus Branding/ to your existing GitHub repo.
   Keep your existing .github/workflows deployment workflow.
7. In GitHub Actions, rerun your normal Web export and Pages deploy workflow.
8. Hard refresh the site with Ctrl+Shift+R. Favicons are strongly cached;
   also try opening the link in a new Incognito window if the old tab logo remains.

WHAT IT DOES NOT DO
- This is a source-project patch, not a prebuilt browser export.
- The Godot Web shell replaces the loading page. It is not a screenshot-only fake UI.
- The original Godot Engine's javascript/wasm/pck are still used internally.
- The browser loading art is embedded into the HTML shell, so it works on
  GitHub Pages even if the deploy action only publishes index.html/index.* files.
- Gemini API is not connected. Never add API keys to a public web game/source.
