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

The latest selected stage header is the Designer Journey reference: connected wavy route, circular numbers, completed ticks, lock medallions and a gold current-stage medal with a translated flag. The loading footer is a compact percentage pill between two gold lines, with no segmented bar. These elements are drawn by code and need no additional image uploads.

Home uses total best stars across the three playable stages (maximum nine) and the saved session stage. Stage 04–10 remain unavailable as before. Start Game, Continue, Retry, save data, best scores, Japanese answers and narration retain their existing behavior.
