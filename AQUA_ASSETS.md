# Aqua artwork and UI

## Background paintings

The owner uploaded these standalone paintings to `main` on 2026-11-20:

| Repository path | Use |
| --- | --- |
| `UIAssets/AquaHome.png` | Centered Home and softly blurred menu backgrounds |
| `LoadingAssets/AquaBuilder.png` | Native and browser loading background |

The paintings contain no UI, logo or progress text. Godot draws real localized controls over them. If either painting is absent, the corresponding original background remains a fallback. Pages automatically copies the uploaded loading picture for the browser shell. Do not upload the full design mockups as backgrounds.

## Logo and navigation

`LoadingAssets/KitchenLogo.webp` now uses the requested brighter aqua coloring while retaining the original logo composition, wording, blueprint scroll and yellow pencil. It is a transparent WebP exported from the generated recolor. The shared logo resource is used throughout the game and copied into the Web loading shell.

The current header uses compact numbered tabs with a localized current-stage label, completion checks and locks. The earlier glass bubbles/waves and flag styles were superseded after user feedback. Buttons use the original pre-Aqua `KitchenUI.style_button` renderer again: the original primary gradient, pale secondary controls and no pearl rings. Text remains centered with balanced icon reservation. The loading percentage pill and gold side lines remain.

Stage 1's conversation card is 300px high, close to Stage 2's measured 293px. Its reference card starts about 13px below Stage 2's reference at the standard viewport. Long conversation text remains available through the existing scroll area. Stage panels and drawing background use muted aqua rather than near-white; original plan images and answer colors retain their meaning.

Home uses total best stars across the three playable stages (maximum nine) and the saved session stage. Stage 04–10 remain unavailable as before. Start Game, Continue, Retry, save data, best scores, Japanese answers and narration retain their existing behavior.
