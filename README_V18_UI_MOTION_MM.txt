Sketch Challenge V18 - UI Motion and Stage Complete
=================================================
Source: The project uploaded as Sketch_Challenge_Levels_Menu_Godot(1).zip.

CHANGES (menu and success presentation only):
1. Home in paused game: BACK TO GAME is anchored top-right, no longer clipped
   at the bottom of the intro panel.
2. Home text: larger/darker font on buttons and description for legibility.
3. Home motion: gentle kitchen photo zoom, title fade-in and staggered buttons.
   These are live Godot Control animations and remain interactive.
4. Stage Complete: shared animated confetti, bouncing checkmark and original
   short success chime (MenuAssets/stage_complete_chime.wav).
5. Stage 1: success voice -> celebration -> Next Stage / Levels.
6. Stage 2: correct AI or local result -> celebration -> Next Stage / Replay / Levels;
   voice-completion and browser-audio fallback are handled.
7. Stage 3: completion after the existing 7 correct choices -> celebration
   -> Replay / Levels. Stages 4-6 are still Coming Soon.

UNCHANGED: DrawingCanvas.gd, GameProgress.gd, MenuExtras.gd, AIConfig.gd,
Stage3Assets imagery, customer dialogues and answer validation logic.
Stage 1/2/3 scripts contain small added success callbacks; their existing
questions, drawing behavior and AI rules were not changed.

HOW TO INSTALL:
FULL ZIP: unzip, open Sketch_Challenge_Game/project.godot with Godot 4.x.
PATCH ZIP: back up original project, extract the patch files directly into
res:// (project root). Preserve the MenuAssets/ subfolder.
After opening allow Godot to finish importing the new WAV file.

TEST:
A. F5 > Stage 1 > LEVELS > Home icon: BACK TO GAME must show fully.
B. Back to Game resumes stage without losing the drawing.
C. On the Home page, background slowly zooms; text/buttons fade in.
D. Clear Stage 1 -> animated Stage Complete, Next Stage opens Stage 2.
E. Clear Stage 2 -> Next Stage opens Stage 3; Replay works.
F. Clear Stage 3 -> animated success, Replay and Levels work.
G. Settings > Mute audio affects the success chime too.

NOTES:
The complete project was statically verified and all ZIP assets are present.
Godot Engine runtime is unavailable in this packaging environment, so the
project has not been executed in the Godot Editor or browser. Test with F5
before deploying to GitHub Pages.
For crisp browser text, test at browser Zoom 100% and native resolution.
