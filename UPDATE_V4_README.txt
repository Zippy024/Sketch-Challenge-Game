SKETCH CHALLENGE — V4: PAUSE MENU + RESUME + RESTART
==================================================
Built from: Sketch_Challenge_Clean_Menu_V3
For: Godot 4.x desktop and Web export

CHANGES
1. Stage 1 and Stage 2 top-right MENU button is now a subtle green outlined "LEVELS" button.
2. LEVELS opens GameMenu.tscn as a fullscreen overlay. The current stage scene is NOT freed.
3. BACK TO GAME resumes the same instance: drawn lines, answer text, audio position, and status remain.
4. Choosing Level 01 in this menu opens a fresh Stage 1 scene and clears the old drawing (intentional restart).
5. Choosing an already unlocked Level 02 starts a fresh Stage 2 scene.
6. Level 02 remains locked until Stage 1 calls Progress.unlock_level(2) after a CORRECT answer.
   The level unlock is saved in user://sketch_challenge_progress.cfg, so prior completions stay unlocked.
7. Smaller language buttons in gameplay header allow space for LEVELS.
8. Sharper downsampled avatar asset customer_portrait_ui.png for the small 110px circular photo;
   original customer_portrait.png kept untouched. Reference sketch and its zoom behavior remain intact.
9. Stage 2 zoomable reference viewer uses mipmap-capable linear filtering.
10. Stage 1 timer-based text/transition callbacks respect SceneTree pause.

TEST CHECKLIST
* F5 -> START GAME -> Level 01: stage starts with customer dialogue.
* Draw a few lines -> LEVELS -> BACK TO GAME: lines remain exactly as before.
* LEVELS -> Level 01: all lines clear and level restarts from its beginning.
* Level 02 is locked for a NEW player. Complete Level 01 successfully to unlock.
* Level 02 -> type into answer box -> LEVELS -> BACK TO GAME: text stays.
* Japanese and Myanmar: render correctly using WebBilingualTheme.tres.

PREVIOUSLY UNLOCKED LEVEL 2?
Progress is persistent by design. If you previously passed Level 1, Level 2 should remain unlocked.
For a clean browser test use an Incognito/Private window (fresh site storage), or clear that site's data.
Do not manually change project data just to reset the state of existing players.

DEPLOYMENT
Test a NEW FOLDER first in Godot, then replace project files in your GitHub Desktop clone.
Preserve the existing .github/workflows/main.yml file from GitHub; not included in this source ZIP.
Commit and Push, wait for GitHub Pages deployment success, hard-refresh your Web game.

AI SECURITY
Do not put Gemini/OpenAI API keys in .gd, .tres, HTML, or your public GitHub repository.
Use a backend endpoint to hold secrets; integrate AI only after the game flow is tested.

LIMITATION
Code and asset-path checks were performed. The Godot executable is not available in this
working environment, so Desktop/Web runtime behavior must be tested in your Godot editor.
