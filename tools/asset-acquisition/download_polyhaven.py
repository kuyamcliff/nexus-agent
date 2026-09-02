#!/usr/bin/env python3
"""Downloads a curated list of Poly Haven CC0 assets (textures/HDRIs) via their public API.

Source: https://polyhaven.com/  |  API docs: https://api.polyhaven.com/
License: CC0 1.0 Universal for everything Poly Haven hosts - no attribution required,
commercial use fine, no restrictions.

Usage:
    python3 tools/asset-acquisition/download_polyhaven.py [--resolution 2k] [--dest DIR]

Edit CURATED_ASSETS below to change what gets pulled. Deliberately curated, not "download
everything" - see the racing-game asset brief for why (asphalt/road surfaces, concrete,
gravel/dirt, and a couple of outdoor HDRIs for lighting reference).
"""
import argparse
import json
import os
import sys
import urllib.request

API_BASE = "https://api.polyhaven.com"
FILES_BASE = "https://api.polyhaven.com/files"
USER_AGENT = "nexus-agent-asset-acquisition/1.0 (+https://github.com/kuyamcliff/nexus-agent)"

# (asset_id, asset_type) - type is "textures" or "hdris"
CURATED_ASSETS = [
    ("aerial_asphalt_01", "textures"),
    ("rocky_terrain_02", "textures"),
    ("concrete_wall_006", "textures"),
    ("gravel", "textures"),
    ("brown_mud_leaves_01", "textures"),
    ("kloofendal_48d_partly_cloudy_puresky", "hdris"),
    ("qwantani_dusk_2_puresky", "hdris"),
    ("overcast_soil_puresky", "hdris"),
]


def fetch_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def download_file(url, dest_path):
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
    print(f"  downloading {url}")
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=60) as r, open(dest_path, "wb") as f:
        f.write(r.read())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--resolution", default="2k", help="e.g. 1k, 2k, 4k (default: 2k)")
    ap.add_argument("--dest", default="Assets/GameAssets", help="base dest dir")
    args = ap.parse_args()

    for asset_id, asset_type in CURATED_ASSETS:
        print(f"{asset_id} ({asset_type})")
        try:
            files = fetch_json(f"{FILES_BASE}/{asset_id}")
        except Exception as e:
            print(f"  FAILED to fetch manifest: {e}", file=sys.stderr)
            continue

        if asset_type == "hdris":
            out_dir = os.path.join(args.dest, "HDRI", asset_id)
            variants = files.get("hdri", {}).get(args.resolution, {})
            # prefer .hdr, fall back to .exr
            entry = variants.get("hdr") or variants.get("exr")
            if not entry:
                print(f"  no {args.resolution} hdri found, skipping", file=sys.stderr)
                continue
            url = entry["url"]
            ext = os.path.splitext(url)[1]
            download_file(url, os.path.join(out_dir, f"{asset_id}{ext}"))
        else:
            # Shape is files[map_name][resolution][format], e.g.
            # files["Diffuse"]["2k"]["jpg"]. Skip package-style entries
            # (blend/gltf/mtlx) - those bundle their own textures already.
            out_dir = os.path.join(args.dest, "Textures", asset_id)
            found_any = False
            for map_name, resolutions in files.items():
                if map_name in ("blend", "gltf", "mtlx"):
                    continue
                variants = resolutions.get(args.resolution)
                if not variants:
                    continue
                entry = variants.get("jpg") or variants.get("png") or variants.get("exr")
                if not entry:
                    continue
                url = entry["url"]
                ext = os.path.splitext(url)[1]
                download_file(url, os.path.join(out_dir, f"{map_name}{ext}"))
                found_any = True
            if not found_any:
                print(f"  no {args.resolution} maps found, skipping", file=sys.stderr)

    print("\nDone. Add a license-registry.json entry per asset: license CC0 1.0, source "
          "https://polyhaven.com/a/<asset_id>")


if __name__ == "__main__":
    main()
