# Licenses

`asset-registry.json` is the single source of truth for what's allowed to ship. Every
asset under `Assets/GameAssets/` must have a matching entry here **before** it's
considered usable in the project — not after.

Run `python3 tools/asset-acquisition/verify_asset_registry.py` to check the registry for
missing required fields. It does not (and cannot) verify that a claimed license is
actually valid — that's a human judgment call, especially for real-vehicle trademark/design
rights, which a marketplace asset's stated license does not by itself establish (the
seller licenses their model file; they don't necessarily hold rights to the vehicle
design or brand). See `docs/asset-acquisition-report.md` for the current OEM-verification
status of each hero car.
