# GameAssets

Asset foundation for the racing game. This is organizational scaffolding only —
**no Unity project has been initialized yet** (no `.unity` scenes, no `Packages/manifest.json`,
no `ProjectSettings/`). That's a deliberate boundary: this pass builds the folder structure,
license-tracking system, and acquisition tooling; it does not start gameplay implementation.

Every binary asset placed under here (models, textures, audio, video) should be tracked via
Git LFS — see `.gitattributes` at the repo root. Every asset, no exceptions, needs a matching
entry in `Licenses/` before it's considered part of the project — see
`Licenses/asset-registry.json` and `Licenses/README.md`.

## Layout

- `Cars/<Manufacturer>/` — the ~50-car hero fleet, one subfolder per manufacturer
- `Tracks/` — racing circuits and routes
- `Environment/` — reusable world-building kits (roads, track infrastructure, urban, nature)
- `Traffic/` — generic/background vehicles (Kenney CC0 kits), kept separate from licensed hero cars
- `Materials/` — shared PBR materials (asphalt, rubber, paint, glass, interior, etc.)
- `Textures/` — source textures backing the materials above
- `Audio/` — engine, environment, and UI sound
- `VFX/` — particle/VFX Graph effects (smoke, sparks, weather, debris)
- `UI/` — HUD and menu assets
- `Characters/` — drivers, pit crew, marshals, spectators
- `Animations/` — character and vehicle animation clips
- `HDRI/` — sky/lighting environments (Poly Haven CC0)
- `Decals/` — livery, signage, road-marking decals
- `Props/` — miscellaneous set-dressing
- `Licenses/` — one license record per asset, mirrored by category

See `tools/asset-acquisition/` for the scripts and research manifests that populate this
tree, and `docs/asset-acquisition-report.md` for the current status of what's actually
been acquired versus what's still a researched candidate.
