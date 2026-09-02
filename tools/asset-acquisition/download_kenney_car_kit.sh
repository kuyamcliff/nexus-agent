#!/usr/bin/env bash
# Downloads Kenney's Car Kit (CC0) for use as generic traffic / prototype vehicles.
# Source: https://kenney.nl/assets/car-kit
# License: CC0 1.0 Universal (public domain) - no attribution required, commercial use fine.
set -euo pipefail

URL="https://kenney.nl/media/pages/assets/car-kit/1a312ec241-1775131960/kenney_car-kit.zip"
DEST_DIR="${1:-Assets/GameAssets/Traffic/KenneyCarKit}"
DOWNLOAD_DIR="tools/asset-acquisition/downloads"

mkdir -p "$DOWNLOAD_DIR" "$DEST_DIR"
echo "Downloading Kenney Car Kit from $URL"
curl -fSL -o "$DOWNLOAD_DIR/kenney_car-kit.zip" "$URL"
unzip -q -o "$DOWNLOAD_DIR/kenney_car-kit.zip" -d "$DEST_DIR"
echo "Extracted to $DEST_DIR"
echo "Remember to add a license-registry.json entry (license: CC0 1.0, source: $URL)."
