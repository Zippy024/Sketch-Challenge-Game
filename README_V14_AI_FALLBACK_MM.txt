SKETCH CHALLENGE — VERSION 14
3 Gemini Models -> Local Fallback for Stage 2 (PS Answer Checking)

What's new:
  1) Gemini 3.8 Flash primary: gemini-3.8-flash
  2) Gemini 3.5 Flash-Lite backup: gemini-3.5-flash-lite
  3) Gemini 3.1 Flash-Lite backup: gemini-3.1-flash-lite
  4) No AI model available / internet down -> Godot Local checker

IMPORTANT: No second Gemini API key is necessary.
API Key stays ONLY in Cloudflare Worker Secret GEMINI_API_KEY.
Never copy your API Key into a .gd file or into GitHub.

SETTING UP — Step by step

A) Backup your WORKING Godot Project.
B) Copy the V14 Stage2.gd into your existing Godot project root and overwrite the older Stage2.gd.
   Other scripts / images / fonts / audio / game scenes are unchanged.
C) In Cloudflare Dashboard, open the existing sketch-challenge-ai Worker -> Edit code.
   Replace the entire worker.js with CloudflareWorker/worker.js from this package.
   Click DEPLOY. Your existing GEMINI_API_KEY secret stays unchanged.
D) Open Godot, press F5, go to Stage 2 and submit an answer.
   The Answer Area status line shows which model evaluated the answer.
   When network is unavailable it shows LOCAL CHECK · APPROXIMATE.
E) After testing, push updated Stage2.gd and other project source changes to GitHub.
   The Cloudflare worker is deployed separately in Cloudflare.

The successful Cloudflare JSON response is now:
  {"correct":true,"source":"gemini","model":"gemini-3.8-flash","tier":1}
Or false / backup model. Correct=false DOES NOT trigger a backup model.

If all Gemini models fail, the Worker returns HTTP 503:
  {"error":"ai_unavailable","fallback":"local"}
Godot recognizes this as a temporary AI outage and invokes its own local checker.

LOCAL MODE IMPORTANT:
- Local keyword/pattern checking is APPROXIMATE; unlike Gemini it cannot truly understand every paraphrase.
- A valid answer might be rejected. The screen explicitly says 'LOCAL CHECK · APPROXIMATE'.
- No stage-1 drawing, PS reference motion, customer audio, menu or saved progress is modified.

SECURITY / QUOTAS
- All three models are charged/limited under your Google project; different model does not guarantee quota availability.
- Because the website is public, please configure Cloudflare's rate limiting / abuse protection before public launch.
- No API keys or credentials are included in this ZIP.

TESTING NOTES
- Cloudflare worker logic was tested locally with mocked HTTP upstream responses for success, model fallback, quota and CORS.
- It has NOT been deployed to your real Cloudflare account or run through the Godot engine in this environment.
- If opening Project ZIP as a new Godot project, the Project's main scene settings may need an editor rescan.
