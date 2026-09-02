# Sonniss GDC Audio Bundle — manual step

**Not downloaded here.** `gdc.sonniss.com` returns HTTP 403 from this container (likely
bot/WAF blocking on datacenter IPs — Sonniss's site is not reachable via a simple `curl`
the way Kenney/Poly Haven are), and even if it were reachable, the bundle is reported at
7.47GB — far more than the ~15GB free in this ephemeral container, and it's a one-time
manual download on their site regardless (no stable, versioned direct-download API to
script against).

## What to do on your real machine

1. Go to https://gdc.sonniss.com/ and download the current bundle (currently listed as
   7.47GB+, 347+ files).
2. Read and keep a copy of the license: https://sonniss.com/gdc-bundle-license/
   - Sonniss's GDC bundles are royalty-free for commercial use, but **do not redistribute
     the raw files as a standalone pack** — only ship the specific sounds you actually
     integrate into the game's audio system, per the license terms.
3. Extract only what the game needs (engine layers, tire/surface sounds, environment
   ambience, collision/impact, UI) into `Assets/GameAssets/Audio/`, organized to match
   the categories in the racing-game audio brief (engine RPM layers, tire/surface,
   weather/environment, UI).
4. Add one `asset-registry.json` entry **per extracted sound or logical group**, not one
   entry for the whole bundle — e.g. `"assetName": "Sonniss GDC 2026 - engine_v8_idle_01"`,
   with `"license": "Sonniss GDC Bundle License"`, `"licenseDocument"` pointing at the URL
   above, and a note on which specific files/folders from the bundle they came from.
5. Keep the bundle's own license text/readme somewhere in your local records (not
   necessarily committed to the game repo) in case provenance is ever questioned.

This file exists so the acquisition pipeline has a documented, correct next step instead
of a silently skipped phase.
