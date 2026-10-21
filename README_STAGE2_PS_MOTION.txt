Sketch Challenge - Stage 2 Animated PS Reference (V12)
======================================================
Open project.godot with Godot 4.7.2 and press F5.

What's changed:
- Stage 2 only: Uses res://reference_ps_stage2.png (the three PS positions circled in red).
- Stage 2 viewer animates extra red pulse rings briefly at the three PS locations.
- The red PS circles remain on the image after the motion ends.
- The zoomable reference popup replays the pulse upon opening it.
- Rings follow image scaling / zoom / pan because they are drawn inside PlanViewer.
- Stage 1 drawing, Stage 2 answer logic, dialogue/audio, fonts, menu and progress code are unchanged.
- AIConfig.gd is set to your PUBLIC Cloudflare Worker URL; there is no API key inside this project.

How to test:
1. Extract the complete ZIP into its own folder.
2. Open project.godot in Godot 4.7.2.
3. Press F5 and navigate to Stage 2 (must have Stage 1 unlocked).
4. See 3 red PS spots pulse briefly, then remain highlighted.
5. Click reference image or Reference Plan title to open popup: pulses replay at larger size.
6. Zoom / pan and check that rings track the PS labels.
7. Try the Gemini AI answer check and Japanese / Myanmar toggles.

To update an existing project instead of switching projects:
Copy only Stage2.gd and reference_ps_stage2.png into the project root.
Keep your existing AIConfig.gd if it already has the right public Worker URL.

Notes:
This ZIP was statically inspected, but has not been run in an installed Godot engine here.
Back up the working project before replacing source files.
