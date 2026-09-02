# Asset Acquisition Report

Generated: 2026-09-02. This update covers turning the researched candidate list into
`tools/asset-acquisition/final-50-cars.json`, plus a real per-listing verification pass.
Nothing beyond cars + the earlier CC0 proof-of-concept has been acquired.

## Environment re-check (per this phase's instruction 1)

Re-audited before touching anything - **unchanged from the prior pass**: same Claude Code
remote session container, not a persistent workstation. Ubuntu 24.04.4, 4 vCPU, 15Gi RAM,
x86_64, **no GPU** (`/dev/dri` absent), Unity 6000.0.82f1 installed (unlicensed), Blender
4.0.2, Git 2.43.0 + LFS 3.4.1, Python 3.11.15, FFmpeg 6.1.1. Disk: 23GB used / 15GB free
of a fixed ~30GB session allowance that does not persist after the session ends.

**This is not "the real development machine."** I flagged this plainly before doing any
work this phase. It means the same constraint as before applies: no payment method, no
marketplace logins, so nothing in the 50-car list can actually be bought or downloaded
from here. What changed this pass is depth of research, not acquisition capability.

## 1. Cars

### Final 50-car manifest

`tools/asset-acquisition/final-50-cars.json` - one selected candidate per vehicle, built
from the existing `hero_car_candidates.json` research (not redone from scratch). Three
primary picks were corrected during this pass because they weren't real, purchasable
listings:

| Car | Problem found | Fix |
|---|---|---|
| Lamborghini Aventador | Top pick was a Sketchfab **tag/search page**, not an individual listing | Found and verified the actual listing: `lamborghini-aventador-a2c10ae...` by HackNetAyush |
| Bugatti Chiron | Top pick was a CGTrader **category page** ("Bugatti Chiron category, 637 models"), not a listing | Swapped to the specific listing already in candidates: `bugatti-chirongame-car...` by Alexander_Dubai |
| BMW M4 CSL | Top pick (zifir3d, 2022) - **listing has been deleted** (confirmed via live fetch: "Model deleted") | Swapped to `bmw-m4-csl-...` by RPMRender |
| Nissan 370Z | Top pick was the flagged **DO_NOT_USE** candidate | Swapped to the CGTrader alternative; the rejected listing is recorded on the entry as `rejectedAlternateCandidate` with status `DO_NOT_USE` so it can't get bought by accident |

### Real verification vs. research-only (honest breakdown)

- **4 of 50** (BMW M4, M5, M8, M2) were individually fetched and their actual page
  content read - real creator name, real polygon counts, and (for the M2) real license
  text. These carry genuine `polyCount` and detailed `verificationNotes`.
- After those 4, the fetch tool started returning empty content for further Sketchfab
  pages in this session - `curl` confirmed the pages themselves are real and populated
  (their `<title>` resolves correctly), so this reads as fetch-tool rate-limiting, not
  broken listings. I did not keep retrying indefinitely once the pattern was clear.
- **CGTrader and TurboSquid individual listing pages are not fetchable from this
  container at all** - they return an empty HTTP 202 bot-challenge response even to
  `curl` with a real browser User-Agent. This was tested, not assumed. No attempt was
  made to bypass it (that would cross the brief's own "do not scrape / do not bypass"
  rule) - those 17 entries (mostly CGTrader) stay at search-snippet-level research.
- **The remaining 46 of 50 entries are honestly marked** in `verificationNotes` as
  research-only, with an explicit instruction to open the URL and verify before buying.

One real quality flag surfaced by the verification: the BMW M2 candidate (RPMRender) is
**422.8k triangles** - far above the 30-60k range other "game ready" listings in this set
claim, despite also being labeled game-ready. Worth checking whether that's actually
usable before buying it, or whether the CGTrader "M mk2" search category has a better fit.

### Status of all 50

Every entry's `status` is **`PURCHASE_REQUIRED`** - a plausible, non-broken candidate
was identified, but **none have been purchased, downloaded, or imported**. Per the
brief's own rule: I do not report an asset as acquired unless it exists locally and has
passed validation, and none do yet.

### OEM permission

**Still zero of 50 have an `oemPermissionReference` filled in.** That field exists in
the manifest specifically for you to fill in as you clear each vehicle through your
manufacturer relationship - it's not something I can populate from marketplace research,
since a listing's license and OEM trademark permission are two separate things (see the
prior report for the full explanation, unchanged this pass).

## 2. Audio

**Unchanged - not acquired.** Sonniss's GDC bundle site returns HTTP 403 from this
container; even if reachable, 7.47GB doesn't fit the 15GB budget. See
`tools/asset-acquisition/sonniss_gdc_bundle.md` for the manual steps. No automotive
sound library research was done this pass (out of scope for "continue the car pipeline").

## 3. Tracks

**Not started.** Zero acquired, zero researched this pass.

## 4. Environment

**Unchanged from last pass**: Kenney Racing Kit (CC0, prototype track props) and 8 Poly
Haven CC0 texture/HDRI sets at 1k proxy resolution are downloaded and registered. No new
environment assets acquired this phase - this pass's effort went into the car manifest
per your "continue from where you left off, don't redo research" instruction.

## 5. VFX

**Not started.** Zero acquired.

## 6. Materials

**Unchanged**: 5 Poly Haven material sets (asphalt, rocky terrain, concrete, gravel,
mud) at 1k, already registered from the prior pass. Nothing new this phase.

## Storage

| | Size |
|---|---:|
| Current repo disk usage (`.git`, LFS objects included) | 74MB |
| Source assets (raw downloads, gitignored, not committed) | ~11MB (Kenney zips, kept locally in `tools/asset-acquisition/downloads/`, not pushed) |
| Processed/Unity-imported assets | 0 - no `SourceAssets/ProcessedAssets/UnityAssets` split exists yet; nothing has gone through an import pipeline because zero real car files exist to import |
| Audio | 0 |
| Environment (Kenney + Poly Haven, committed) | ~69MB |
| Cars (models) | 0 - folder structure only |
| Free space in this container | 15GB of ~30GB fixed allowance |
| Estimated future requirement for 50 real hero cars | Rough order of magnitude from the marketplace listings seen this pass: individual game-ready car models here run from a few MB (mobile-optimized, ~1MB per the BMW M5 listing) up to several hundred MB for high-poly/interior-included listings (one Ferrari F8 Tributo candidate alone is 613k polygons with full interior). 50 cars at a realistic mixed quality bar is plausibly **2-8GB of source assets**, likely doubling or more after Unity import (uncompressed textures, LODs, prefab variants) - all of which needs a real machine, not this container |

## What's next

1. **You**: open `tools/asset-acquisition/final-50-cars.json`, work through each entry -
   verify quality against the brief's checklist (rule 6), confirm license text, fill in
   `oemPermissionReference`, purchase, download, flip `status` to `PURCHASED` then
   `DOWNLOADED` as you go. Start with the 4 pre-verified BMW entries since those already
   have real poly-count data to sanity-check against.
2. Do NOT buy the flagged Nissan 370Z listing under any circumstance - use the recorded
   alternate.
3. Once at least one real car file exists locally, the import pipeline (Section 15/16/17
   of the brief) becomes buildable and testable - building it against zero real assets
   would just be speculative scaffolding, so it's still deliberately not started.
4. Everything else (audio, tracks, environment expansion, VFX) stays queued behind cars,
   matching the brief's own phase ordering.
