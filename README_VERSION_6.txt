SKETCH CHALLENGE V6 — CLEAN TEXT-ONLY MENUS

Changes from V5:
- Home: no photographic hero, no large blurry image. All menu elements are native Godot Controls.
- Level selection: simple text rows. Stages 1 and 2 show titles/description/status only.
- Stage 2 stays LOCKED until Stage 1 is successfully completed.
- Stages 3, 4, 5 and 6 have ONLY number + COMING SOON (no title/description/thumbnail).
- Back to Game when opened from an active stage resumes the paused game without erasing drawings/answers.
- Clicking an unlocked Level row starts that level from the beginning.
- Original bilingual Theme, audio, drawing and Q&A logic preserved.

TEST
1. Open project.godot with Godot 4.7.2, press F5.
2. Click START GAME. Confirm Stage 2 says LOCKED until Stage 1 passed.
3. Click Stage 1; draw something; press LEVELS; press BACK TO GAME; drawing should remain.
4. Press LEVELS again and choose Stage 1: this deliberately restarts the level.
5. For already unlocked saved progress, Home > SETTINGS > RESET LEVEL PROGRESS > CONFIRM RESET.
6. Test Stage 2, Japanese and Myanmar, then upload to GitHub after successful local test.

Do not publish Gemini API keys in your Godot/GitHub Pages source. Use a backend later.
This package was source-checked but was not run inside the Godot editor/browser here.
