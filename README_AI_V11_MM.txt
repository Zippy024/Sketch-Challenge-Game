SKETCH CHALLENGE — V11, GEMINI AI READY

V9 gameplay + V10 logo/splash update + Stage 2 Gemini AI HTTP checker.

STEP 1: Open this project.godot using Godot 4.7.2. Check Stage 1/2.
STEP 2: Read CloudflareWorker/README_SETUP_MM.txt and deploy worker.js.
STEP 3: Store GEMINI_API_KEY in Cloudflare Workers secret; NEVER share it.
STEP 4: Set AIConfig.gd API_URL to https://YOUR-WORKER.workers.dev/check
STEP 5: Play Stage 2 and test two answers in JP/MM. Expect 'correct' or 'wrong', not hints.
STEP 6: Commit updated project (including AIConfig.gd URL, NOT secret) and deploy via GitHub Actions.

V10 branding: Boot splash now PNG (Godot does not accept JPG for boot splash); custom HTML shell and favicon kept.
Note: No live Gemini request could be verified without your private API key and deployed Cloudflare Worker.
