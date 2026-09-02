# Asset Acquisition Report

Generated: 2026-09-02. Covers Phase 1 (hero cars) research plus a small proof-of-concept
pull of free/CC0 assets. Nothing else from the 23-phase brief was attempted this pass -
see "What's next" at the end.

## Environment check (done before any downloads, as required)

- Unity version: 6000.0.82f1, installed and working, **no license activated**
- Existing folder structure / assets / packages / vehicle systems / scripts: **none** -
  this repo had only a README before this session
- Git: 2.43.0, LFS 3.4.1 now initialized (`.gitattributes` added, tracks fbx/obj/gltf/
  glb/blend/png/tga/tif/exr/hdr/psd/wav/mp4/mov/fsb/bank/unitypackage)
- Disk: ~15GB free of a fixed ~30GB session allowance, in an ephemeral container that
  does not persist after this session
- Network: reachable - Sketchfab, CGTrader, Unity Asset Store, Fab, Hum3D, Kenney, Poly
  Haven, FMOD. **Blocked (HTTP 403) from this container**: TurboSquid, ArtStation
  Marketplace, Sonniss's GDC bundle site
- **Verdict: this environment is not suitable for the actual bulk asset downloads.**
  50 hero cars at production quality plus a 7.47GB audio bundle plus environment/HDRI
  libraries would need far more than 15GB and would vanish when the session ends anyway.
  Per the brief's own fallback instruction, this pass built the research and tooling
  (`tools/asset-acquisition/`) rather than pretending to download the bulk of it.

## What was actually downloaded (real, verified, present in the repo)

| Asset | Source | License | Size |
|---|---|---|---|
| Kenney Car Kit (40+ generic vehicles) | kenney.nl | CC0 1.0 | 15MB |
| Kenney Racing Kit (track props) | kenney.nl | CC0 1.0 | 21MB |
| 5 Poly Haven texture sets (asphalt, rocky terrain, concrete, gravel, mud) | polyhaven.com | CC0 1.0 | 29MB (1k proxy res) |
| 3 Poly Haven HDRIs (partly cloudy, dusk, overcast) | polyhaven.com | CC0 1.0 | 3.7MB (1k proxy res) |

All 10 have real, verified `asset-registry.json` entries. Total: **~69MB**, all CC0 -
no licensing risk, no OEM concerns (none are real-brand vehicles). Poly Haven assets
were pulled at 1k for prototyping only; re-pull at 4k/8k on the real dev machine before
shipping (the download script takes a `--resolution` flag for this).

Both download scripts hit real bugs during this pass and were fixed for real, not just
written speculatively: Poly Haven's API blocks Python's default `urllib` User-Agent
string with a 403 (fixed by setting an explicit UA), and the texture JSON's actual shape
(`files[map_name][resolution][format]`) didn't match my first guess (`files[resolution]
[map_name][format]`) - both are corrected and the scripts now run cleanly end to end.

## Which 50 cars: full researched candidate list

All 50 cars from the brief were researched (one to two web searches each against
Sketchfab/CGTrader/RenderHub/TurboSquid-via-snippet). Full detail with URLs and notes
is in `tools/asset-acquisition/hero_car_candidates.json`. **None have been purchased or
downloaded** - every one needs manual verification and a real purchase on your machine.

Summary by manufacturer (all 50 have at least one plausible candidate):

| Manufacturer | Cars | Candidates found |
|---|---|---|
| BMW | M3 E46, M4, M4 CSL, M5, M8, M2, M3 E30 | 7/7 |
| Lamborghini | Aventador, Huracán, Revuelto, Urus, Huracán STO | 5/5 |
| Ferrari | 488 GTB, 488 Pista, F8 Tributo, 296 GTB, SF90 Stradale | 5/5 |
| Porsche | 911 GT3, 911 GT3 RS, 911 Turbo S, 918 Spyder, Cayman GT4 | 5/5 |
| Mercedes-AMG | GT, GT Black Series, C63, E63, ONE | 5/5 |
| McLaren | 720S, 765LT, Artura, 750S, P1 | 5/5 |
| Audi | R8, RS6 Avant, RS3, RS7 | 4/4 |
| Nissan/Toyota/Honda | GT-R R35, 370Z, GR Supra, GR86, NSX, Civic Type R | 6/6 |
| American/Muscle | Mustang GT, Shelby GT500, Corvette C8, Camaro ZL1, Challenger SRT Hellcat | 5/5 |
| Hypercars | Jesko, Chiron, Huayra | 3/3 |
| **Total** | | **50/50** |

**Missing: none at the candidate-research level** - every model had at least one
plausible marketplace listing. "Missing" in the sense that matters is different: **zero
of the 50 have been verified against the brief's actual quality checklist (poly/texture/
PBR/LOD/interior/wheel detail) or purchased**, so treat the count above as "a starting
point was found," not "acquired."

### Flags worth reading before you buy

- A few candidates are non-stock variants (widebody kits, race/track trims, special
  editions) rather than the base model named in the brief - flagged per-car in the JSON.
- One Nissan 370Z Sketchfab listing's own description says it's "based on a Real Racing 3
  3D model" - that's a red flag for being a derivative of another commercial game's
  asset. Don't use it; a CGTrader alternative is listed instead.
- One Ferrari F8 Tributo listing is explicitly "unbranded" (deliberately de-branded to
  avoid trademark issues) - useful signal that even 3D artists treat Ferrari's design as
  legally sensitive; re-branding it would need its own trademark clearance.
- Several listings' "free" or "CC-BY" license claims come from search-result snippets,
  not a page I opened and read myself - the JSON says explicitly which of these need
  direct verification before you trust them.

## OEM/trademark verification status

**Zero of the 50 cars have an `oemPermissionReference` on file.** You said you have the
necessary permission/licensing for the real vehicle brands - that covers your
relationship with the manufacturers, but it does not automatically extend to any
specific marketplace 3D model. Each artist's listing license only covers the file they
made; it doesn't establish they had a right to model the trademarked design in the first
place. `verify_asset_registry.py` will flag (not block) any entry that has a
`manufacturer` set but no `oemPermissionReference` - use that as your checklist as you
work through purchases.

## Tracks, environment, audio, VFX, UI, characters

**Not started.** Per the phase ordering in the brief (Phase 1 first, validate before
moving on), and given the environment's disk/persistence limits, this pass stopped
after cars research + a CC0 proof-of-concept. Kenney's Racing Kit (already downloaded)
gives lightweight prototype track props; Poly Haven (tooling already working) can supply
materials/HDRIs on request. Sonniss audio needs manual download - see
`tools/asset-acquisition/sonniss_gdc_bundle.md`.

## Size of major asset groups (current repo state)

| Group | Size |
|---|---:|
| Textures (Poly Haven, 1k) | 29MB |
| Traffic (Kenney Car Kit) | 21MB |
| Props (Kenney Racing Kit) | 15MB |
| HDRI (Poly Haven, 1k) | 3.7MB |
| Cars | 68KB (folder structure only, no models yet) |
| **Total added to repo this pass** | **~69MB** |

## What needs manual purchase/download

- All 50 hero cars - pick from `hero_car_candidates.json`, verify, buy, download,
  push through the (not-yet-built) import pipeline
- Sonniss GDC audio bundle (7.47GB, site blocked from this container anyway)
- FMOD Unity integration (needs FMOD account + Unity project to integrate into)
- Anything on TurboSquid or ArtStation Marketplace directly (403 from this container -
  open these on your own machine/browser)
- Unity license activation (needs your Unity account credentials)

## What's next

1. Verify and purchase a first batch of hero cars from the candidate list (suggest
   starting with the ones flagged as already "game ready" / real-time-optimized in their
   own listing titles, since those need the least rework)
2. Build the actual import pipeline (Section 17 of the brief) once at least one real
   car file exists to test it against - no point writing 30 pipeline steps against zero
   real assets
3. Move to Phase 2 (generic traffic - Kenney Car Kit already covers a first pass) and
   Phase 3 (tracks) once cars are validated
4. Do this on a real machine with real disk and a real Unity Hub - this container can
   keep doing research/tooling/documentation work, but the actual bulk downloads and
   purchases belong on your persistent workstation
