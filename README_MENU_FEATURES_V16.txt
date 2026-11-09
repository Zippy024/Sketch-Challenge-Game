SKETCH CHALLENGE — MENU-ONLY FEATURES V16
Godot 4.7.x / Web Export

PURPOSE
This update adds common educational-game hub features without changing Stage 1,
Stage 2, Stage 3, their UI, scoring, customer dialogues, audio, answers, drawings,
AI requests, or image assets.

ADDED FEATURES (GameMenu.gd + MenuExtras.gd only)
1. PLAYER PROFILE: optional local/guest display name (no credentials or account).
2. MY PROGRESS: number of starts launched via Level Select; last launched stage.
   Only Stage 1 completion is verified from the existing progress save file.
   Stage 2/3 completion is NOT inferred or invented.
3. ACHIEVEMENTS: First Steps, Stage Explorer, Dedicated Learner,
   Drawing Challenge Clear, based on trackable menu actions / Stage 1 completion.
4. MISSION GUIDE: compact summaries with stage launch buttons.
5. SETTINGS: existing language + volume + stage reset, plus saved volume, mute,
   and user-initiated fullscreen toggle.
6. HOW TO PLAY: shortcut to Mission Guide.
7. LEVEL MENU: Mission Guide shortcut; existing open access for stages 1-3 kept.
8. EXISTING HOME: compact Player Profile / My Progress / Achievements links.

NOTE ON RESULTS
Stage 2/3 results are not saved in the current GameProgress.gd implementation.
Showing their successful completion would require a future change inside those
stage scripts; this update respects the request to leave them untouched.

INSTALLATION
A) FULL ZIP: back up your existing project, extract Sketch_Challenge_Game,
   open project.godot in Godot, run F5.
B) PATCH ZIP: copy GameMenu.gd, MenuExtras.gd, README_MENU_FEATURES_V16.txt
   into the project's res:// root (replace GameMenu.gd only).

TEST PLAN
- Launch Godot F5 and open Home / Settings / How to Play / Levels.
- Open PLAYER PROFILE, save a name, navigate away and back.
- Open MY PROGRESS, check zero-count/last stage, and visit a stage via Levels.
- Return to My Progress: corresponding stage count should increase.
- In ACHIEVEMENTS, First Steps becomes unlocked after the first Level launch.
- Try volume/mute/fullscreen toggles, close/reopen game and check persistence.
- Test Level 1/2/3 from Levels and Mission Guide (Stages 4-6 Coming Soon).
- Verify Stage1/2/3 scene and script SHA256 values are unchanged.
- On Web, settings and the guest profile are stored in the browser's site storage.

LIMITATIONS
- These are frontend / local user-device extras, NOT cloud accounts.
- In-browser fullscreen may require browser permission/user gesture.
- A Godot Engine run test could not be executed in this build environment.
