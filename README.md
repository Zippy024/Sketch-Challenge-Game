# Sketch Challenge – Kitchen Decoration Game

A Godot 4.7.2 three-language web training game, deployed using GitHub Pages.

## Game

- Stage 1: Sketch the customer's kitchen, living and dining boundaries.
- Stage 2: Answer the PS (Pipe Space) question.
- Stage 3: Choose the kitchen layout and identify eight numbered Japanese kitchen parts on the 360° model.

The player must finish listening to the customer before answering. Stages support Retry, local checkpoints and three-star results.

## Where to work

| Path | Purpose |
| --- | --- |
| `Main.gd` and `DrawingCanvas.gd` | Stage 1 |
| `Stage2.gd` | Stage 2 |
| `Stage3.gd` and `Stage3Assets/Model/KitchenModel.gd` | Stage 3 |
| `KitchenUI.gd`, `GameMenu.gd` | Shared UI / menu |
| `GameProgress.gd`, `StageRating.gd` | Progress and stars |
| `Branding/RefinedWebShell.html` | Current Web HTML shell |
| `.github/workflows/deploy-web.yml` | Tests and GitHub Pages deployment |
| `Tests/` | Automated game and language checks |

Open `project.godot` with **Godot 4.7.2**. The editor regenerates `.godot/`; do not commit it. The `.import` configurations, fonts, audio and the active source assets are deliberately retained.

Push changes to `main` for GitHub Actions to run the tests and deploy the web game. The old optional Godot Editor GitPlugin was removed to keep the repository lean. Use an external Git client or GitHub for source control.

## Cleanup and recovery

On 20 November 2026, unnecessary tracked editor cache, unused GitPlugin binaries, exact duplicate source art, an obsolete unused Web HTML shell, historical release notes and unused duplicate code were removed. Nothing was deleted from Git history. To recover old notes or assets, see the complete pre-cleanup snapshot at [`backup/before-cleanup-2026-11-20`](https://github.com/Zippy024/Sketch-Challenge-Game/tree/backup/before-cleanup-2026-11-20).
