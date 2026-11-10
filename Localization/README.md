# Game languages

The shared `LocaleManager` autoload translates menu and stage controls from the English/Myanmar/Japanese catalog in `Messages.gd`. `GameProgress.set_language()` persists the choice and refreshes visible controls. Keep player-entered answers and display names unchanged. Language choices remain written in their own language.

Recorded audio keeps the existing MP3 paths for Japanese and Myanmar. No speech service or API key is used. Optional English recordings can be added at these paths:

- `Voice/en/stage1_talk.mp3`
- `Voice/en/stage1_correct.mp3`
- `Voice/en/stage1_wrong.mp3`
- `Voice/en/stage2_question.mp3`
- `Voice/en/stage2_good.mp3`
- `Voice/en/stage2_needs.mp3`

Without an English recording, the existing text-only flow continues. Stage 3 retains its existing behavior.

Run `godot --headless --audio-driver Dummy --path . --script res://Tests/TrilingualSmoke.gd --max-fps 120 --quit-after 9000` to verify all three languages, ten stage cards, input preservation, and the existing Stage 2/3 answer rules. The control-text report is saved to `user://translation-audit.json`.
