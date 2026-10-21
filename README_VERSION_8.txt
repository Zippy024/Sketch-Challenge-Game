SKETCH CHALLENGE VERSION 8 -- GODOT 4.7.2
==========================================
This is a REAL EDITABLE GODOT PROJECT, not a menu image mockup.

VISUALS
- Intro matches the supplied sunlit kitchen reference: light kitchen photo,
  house/drawing logo, left-side title and descriptor, three clickable bottom
  tile buttons with real image icons. Fonts remain embedded Japanese + Myanmar.
- No baked-in interface text: MenuAssets/KitchenIntroV8.jpg is a plain kitchen
  background. All three menu buttons and text are native Godot controls.
- Level selection is simple text-only rows. No thumbnails/icons.
- Stage 1: CUSTOMER REQUEST underneath the customer name.
- Stage 2: CUSTOMER QUESTION underneath the customer name.
- Dialogue panel is neutral white with a subtle blue-gray border, no green tint.
- In-game buttons are compact.

GAME RULES
- Stage 1 playable immediately.
- Stage 2 LOCKED until the Stage 1 drawing validation returns success.
- Stage 3 through Stage 6: numbers and COMING SOON only.
- LEVELS > BACK TO GAME resumes current game state; selecting an unlocked level
  starts that stage from scratch. Customer audio and the drawing canvas remain.
- A NEW V8 progress file (user://sketch_challenge_progress_v8.cfg) prevents
  old V6/V7 test progress from incorrectly unlocking Stage 2.
- Settings > RESET LEVEL PROGRESS locks Stage 2 again.

HOW TO TRY
1. Extract this whole ZIP into a new folder (do not overwrite your working V7).
2. Open project.godot in Godot 4.7.2, run F5.
3. Confirm HOME > START GAME > STAGE 1 directly enters gameplay.
4. Draw some lines, press LEVELS > BACK TO GAME: drawing remains.
5. Press LEVELS > STAGE 1: scene restarts cleanly.
6. Stage 2 should be LOCKED until Stage 1 passes; then unlocked.
7. Check Stage 1 and Stage 2 Japanese / Myanmar. Run Web only after desktop OK.

DEPLOYMENT
- Keep your already-working GitHub Pages .github/workflows/main.yml.
- Backup existing project; copy this source to the repository root; commit and push.
- Deploy via GitHub Actions. Do NOT commit any private API key to a public repo.
- Gemini AI is NOT integrated into this V8. Plan: backend proxy and server-side key.

TEST STATUS
- File integrity, linked resource existence, key GDScript structure checked.
- Godot 4.7.2 executable was not available in this environment, so no live
  editor or browser runtime test is claimed.
