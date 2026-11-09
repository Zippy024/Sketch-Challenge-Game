STAGE 3 IMAGE IMPORT FIX - GODOT 4.7.2

Error fixed: Preload file res://Stage3Assets/q1_5.png has no resource loaders.
The Stage3Assets PNG images were re-encoded as standard RGB PNG images, with their original picture content and names preserved.

HOW TO INSTALL
1. Close Godot. Back up the current project.
2. Extract this ZIP to a NEW folder (full project) OR copy Stage3.gd and the entire Stage3Assets folder from the patch over the matching paths in your existing project.
3. Open the new/updated project.godot with Godot and allow the file-system import to complete.
4. If Godot still reports stale import errors, close Godot, delete the .godot folder inside the project (cache only), then reopen the project; do not delete assets.
5. Run the game and verify Stage 3 Q1 shows five option images, Q2 shows four.

NOTE: This fixes imported image source format and staging; does not modify Stage1.gd/Main.gd, Stage2.gd, Gemini, or level logic.
