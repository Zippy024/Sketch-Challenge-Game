WEB FONT FIX — Reference project approach

Changes:
- Added NotoSansCJKjp-Regular.otf + NotoSansMyanmar.ttf
- Added WebBilingualTheme.tres using Japanese font with Myanmar fallback
- Stage 1 Main.gd and Stage 2 Stage2.gd now use the SAME theme, no SystemFont
- Project theme set to res://WebBilingualTheme.tres
- Removed Web-only text darkening. No drawing/audio/answer-checking logic changed.
- Existing original variable fonts remain for backup.

How to test:
1. Extract the whole kitchen-layout-final folder.
2. Open project.godot with Godot 4.7.2. Let fonts import.
3. Run locally and test Japanese and Myanmar on Stage 1 and Stage 2.
4. Export Web and test locally via HTTP or GitHub Actions; do not open index.html as file://.
5. Commit changed project files (including new .tres and .otf/.ttf), push and wait for green deployment.
6. Hard refresh Ctrl+Shift+R.

Note: This change targets font availability and consistent rendering. Browser zoom / viewport scaling can still make text look softer than desktop.
