SKETCH CHALLENGE - VERSION 7 (GODOT 4.7.2)
============================================
BASED ON: Tested-by-user V6 design / original Stage 1 & Stage 2 logic.

V7 CHANGES
1. Real interactive HOME intro with a kitchen photograph on the right (MenuAssets/KitchenHero.jpg).
   The left dark-green half has KITCHEN LAYOUT GAME, START GAME, HOW TO PLAY, SETTINGS.
   There is NO "Start with the basics" panel and NO level previews on the Home page.
2. Level Select is text-only. NO photo thumbnails or decorative icons.
   Stage 1: Customer Request | PLAY.
   Stage 2: Pipe Shaft Q&A | LOCKED until Stage 1 is passed (unless previously saved as unlocked).
   Stage 3 / 4 / 5 / 6: COMING SOON only (no titles, previews, thumbnails).
3. Stage 1 heading is STAGE 1. Below the customer name is CUSTOMER REQUEST.
4. Stage 2 heading is STAGE 2. Below the customer name is CUSTOMER QUESTION.
5. Existing drawing, bilingual bundled fonts, audio, progress saving, Stage 2 Q&A,
   LEVELS -> BACK TO GAME resume, and selecting a level to restart are preserved.
6. No API keys in the ZIP. AI integration should be through a backend later.

TRY IT FIRST IN GODOT
- Open project.godot from THIS folder; use F5 for HOME scene.
- START GAME -> choose Stage 1. It goes straight into Stage 1 (no redundant START LEVEL 1).
- Draw a line; press LEVELS -> BACK TO GAME: drawing should remain.
- Press LEVELS -> Stage 1: restart fresh.
- Stage 2 is locked until the Stage 1 drawing answer is successfully checked.
- Stage 2 is a Pipe Shaft Q&A, not 3D kitchen modeling yet.
- If Stage 2 is already unlocked from prior testing, reset in SETTINGS.

TEST STATUS
- Source files and resource paths checked and ZIP archive validated.
- Godot 4.7.2 runtime was not available here; check F5 and errors before GitHub deployment.

GITHUB
- Keep .github/workflows/main.yml from your existing GitHub repository.
- Commit / Push only AFTER successful desktop test, then GitHub Actions deploy.
