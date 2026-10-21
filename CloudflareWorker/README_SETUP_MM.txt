SKETCH CHALLENGE — GEMINI AI (STAGE 2)

1) https://aistudio.google.com/apikey တွင် Gemini API Key ထုတ်ပါ။
2) https://dash.cloudflare.com/ -> Workers & Pages -> Create Worker.
3) Cloudflare Worker Editor တွင် worker.js အပြည့်အစုံ Paste / Deploy လုပ်ပါ။
4) Worker -> Settings -> Variables and Secrets -> Add -> Type: Secret
   Name: GEMINI_API_KEY, Value: မိမိ Gemini API Key. Save/Deploy.
5) Worker URL ကို copy လုပ်ပါ။ ဥပမာ https://sketch-challenge-ai.YOUR-SUBDOMAIN.workers.dev
6) Godot Project ၏ AIConfig.gd ထဲက API_URL ကို
   https://sketch-challenge-ai.YOUR-SUBDOMAIN.workers.dev/check
   ဟုပြင်ပြီး Save လုပ်ပါ။ API KEY မထည့်ပါနှင့်!
7) Godot Stage 2 -> Check Answer နှိပ်စမ်းပါ။
8) Godot OK မှ GitHub commit/push -> Web deploy -> Stage 2 စမ်းပါ။

Stage 1 = Drawing validation unchanged. Stage 2 = Gemini evaluates whether PS is explained correctly.
On success -> original success text/audio; failure -> original needs/try again text/audio. Correct answer NEVER shown.
If Backend URL is still placeholder, Stage 2 runs OFFLINE DEMO keyword checker with clear DEMO label.
Once URL is real and backend is unavailable, no silent offline substitute occurs.

Security:
- API key ONLY in Cloudflare Worker Secret; NEVER in Godot, HTML, public repository, logs or chat.
- Public Worker endpoint can still be abused through direct HTTP calls; CORS alone is NOT authentication.
  Before widely sharing, enable per-IP rate limiting / bot checks / Turnstile and usage budget monitoring.
- Gemini free quotas and model availability depend on your AI Studio project.
- For an alternate GitHub Pages domain, update ALLOWED_ORIGINS in worker.js.
