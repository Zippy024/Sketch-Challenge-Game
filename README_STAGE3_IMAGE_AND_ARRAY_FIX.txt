STAGE 3 UI / IMAGE QUALITY PATCH

Changes:
1. Stage3.gd: fix Godot runtime error "Trying to assign an array of type Array to Array[String]" in _draw_choices by using explicit typed branches.
2. Stage3Assets q1/q2: 3x Lanczos resample with subtle sharpening for cleaner rendering at larger control sizes. Source screenshots remain the limiting factor for detail.

Unchanged: Main.gd, Stage2.gd, GameMenu.gd, GameProgress.gd, Gemini AI backend, audio, Stage 1/2, and stage 3 logic/answers.

Install: Extract Stage3.gd and Stage3Assets folder to your project root (res://), overwrite matching files, restart Godot and try Stage 3 Q1 and Q2.
Note: This does not turn screenshot images into true high-resolution 3D model renders. For sharper original kitchen details, replace q1/q2 PNGs with separately exported high-resolution original images.
