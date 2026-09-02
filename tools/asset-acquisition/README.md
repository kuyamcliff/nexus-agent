# Asset Acquisition Tools

Modular scripts for building the racing game's asset library. See
`docs/asset-acquisition-report.md` for current status of what's actually acquired.

| Script | What it does | Status |
|---|---|---|
| `download_kenney_car_kit.sh` | Downloads Kenney's CC0 Car Kit (generic traffic vehicles) | Real, tested, already run |
| `download_kenney_racing_kit.sh` | Downloads Kenney's CC0 Racing Kit (track props) | Real, tested, already run |
| `download_polyhaven.py` | Downloads a curated list of Poly Haven CC0 textures/HDRIs via their public API | Real, tested, already run at 1k; re-run at higher `--resolution` for production |
| `verify_asset_registry.py` | Validates `Assets/GameAssets/Licenses/asset-registry.json` for missing required fields | Real, tested |
| `hero_car_candidates.json` | Researched (not purchased) candidate marketplace listings for all 50 hero cars | Research only - every entry needs manual verification and purchase on the real dev machine |
| `sonniss_gdc_bundle.md` | Manual instructions for the Sonniss GDC audio bundle (too large / site unreachable from this container) | Documentation only |

## Why some things aren't scripts

Most of the 50 hero cars, and anything behind Unity Asset Store / Fab / TurboSquid /
ArtStation accounts, require a logged-in purchase through each marketplace's own
checkout - there's no API to script that responsibly, and this session has no payment
method or marketplace account to use even if there were. `hero_car_candidates.json` is
the research output that makes those purchases fast to execute manually: open a URL,
verify the asset against the brief's quality checklist, buy it, download it, run it
through the import pipeline, add a registry entry.

## Adding a new acquisition script

Keep scripts modular (one source per script, per the project's own rule against "one
giant script"). A new script should:
1. Print its source URL and license before downloading anything
2. Download to `tools/asset-acquisition/downloads/` (gitignored) or directly to the
   right `Assets/GameAssets/<Category>/` subfolder
3. Remind the caller to add a `Licenses/asset-registry.json` entry (or do it for them,
   as `download_polyhaven.py` could be extended to do)
4. Be runnable standalone with no required arguments (sensible defaults)
