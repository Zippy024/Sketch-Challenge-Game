SKETCH CHALLENGE — VERSION 9 (UI POLISH)

This version is based directly on the user-tested V8 project.

1) Home/Intro: Start Game, How to Play and Settings tiles resized to
   158x98, typography 14px and icon 31x31; cleaner shadows;
   icons supplied as anti-aliased 64x64 PNG source assets.
2) When a running game opens LEVELS, both BACK TO GAME and a HOME
   icon button are shown. HOME displays the Home interface as an overlay,
   leaving the active stage paused underneath. Choose BACK TO GAME
   to continue the exact previous drawing/answer state.
3) Stage 1 retry button is compact (101x30), white/pale coral fill,
   thin border and 12px label. The retry behavior is unchanged.
4) Progress/unlock, Stage 2, Web fonts, dialogue, audio and canvas logic
   are otherwise unchanged from V8.

TEST IN GODOT 4.7.2:
- F5 -> Home: check new tile dimensions and sharpness.
- Start Level 1, draw lines, LEVELS -> BACK TO GAME: lines remain.
- LEVELS -> HOME icon -> BACK TO GAME: lines remain.
- Incorrect drawing -> OK -> Try Again: button appears; retry clears
  canvas and keeps gameplay functional.
- Verify Level 2 lock/unlock rules using a fresh V8 save/reset.

The project has been statically validated (file paths, indentation
checks, zip integrity). The Godot GUI/Web renderer is not available
inside this environment, so in-engine behavior is not claimed tested.
