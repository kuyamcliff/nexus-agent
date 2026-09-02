#!/usr/bin/env python3
"""Validates Assets/GameAssets/Licenses/asset-registry.json against its required schema.

Does NOT validate that a claimed license is actually correct or that a real-vehicle
model's marketplace license implies OEM/trademark clearance - that's a human call. This
only checks that every entry has the required bookkeeping fields filled in, since an
asset with no source/license recorded is not something the project can safely ship.

Usage:
    python3 tools/asset-acquisition/verify_asset_registry.py [path/to/asset-registry.json]

Exit code 0 = clean, 1 = problems found.
"""
import json
import sys

REQUIRED_FIELDS = [
    "assetName", "creator", "source", "downloadDate", "license",
    "commercialUse", "modificationAllowed", "gameDistributionAllowed",
]

REAL_MANUFACTURER_HINT_FIELDS = ["manufacturer", "model"]


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "Assets/GameAssets/Licenses/asset-registry.json"
    with open(path) as f:
        reg = json.load(f)

    entries = reg.get("entries", [])
    problems = []

    for i, e in enumerate(entries):
        label = e.get("assetName") or f"entry #{i}"
        for field in REQUIRED_FIELDS:
            val = e.get(field, None)
            if val in (None, "", []):
                problems.append(f"{label}: missing required field '{field}'")
        if e.get("commercialUse") is False:
            problems.append(f"{label}: commercialUse is explicitly False - should not be used in a shipped build")
        if e.get("manufacturer") and not e.get("oemPermissionReference"):
            problems.append(
                f"{label}: has a real manufacturer ('{e['manufacturer']}') but no "
                f"oemPermissionReference - a marketplace license alone does not establish "
                f"trademark/design rights, this needs manual verification before shipping"
            )

    print(f"Checked {len(entries)} entries in {path}")
    if problems:
        print(f"\n{len(problems)} problem(s):")
        for p in problems:
            print(f"  - {p}")
        sys.exit(1)
    else:
        print("No problems found.")
        sys.exit(0)


if __name__ == "__main__":
    main()
