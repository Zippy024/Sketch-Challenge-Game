WEB FIX PACKAGE — 20 October 2026

Source project extracted from the user's ZIP. Stage 1, Stage 2, audio, images, scripts, and bundled Japanese/Myanmar TTFs are preserved.

Change made:
- Main.gd: Removed the forced 4X 2D MSAA on browser/GLES3, which produced the exact Chrome console warning shown by the user. Web now explicitly disables 2D MSAA. Other platforms retain their project defaults.

Important observations:
- Both scripts already use bundled Noto Sans JP and Noto Sans Myanmar on Web with FontVariation fallbacks. Do not replace them with SystemFont for Web.
- Intro START GAME and voice-driven reference reveal are already implemented in the uploaded code.
- The uploaded source contains no GitHub Actions workflow. KEEP the workflow in your current GitHub repository.
- A blurry canvas can still be caused by browser zoom, OS display scaling, WebGL canvas scaling, or very small text. This package is NOT guaranteed to resolve all blur. Screenshot checks and browser tests remain necessary.
- This environment does not contain a Godot executable or browser for runtime verification. Scripts were reviewed but not run.

Deployment steps:
1. Back up your current project and GitHub repository first.
2. Unzip and open project.godot in Godot 4.7.2.
3. Run Stage 1, then Stage 2 locally and check errors, audio, fonts, and transitions.
4. Upload the project SOURCE files to your existing GitHub repository. Keep the existing .github/workflows folder. DO NOT upload .godot caches, old Web Game exports, or ZIP itself as a substitute for source.
5. Trigger your existing GitHub Actions deployment, wait for green Success, then open https://zippy024.github.io/Sketch-Challenge-Game/ and hard refresh (Ctrl+Shift+R).
6. Set Chrome zoom to 100% and check Web fonts and voice. If still blurred, compare screenshots at different browser zoom and report Console errors.

Do not delete your working GitHub repository just to redeploy. An entirely new repository is not necessary.
