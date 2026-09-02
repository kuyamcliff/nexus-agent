#!/usr/bin/env bash
# Downloads Kenney's Racing Kit (CC0) for track props / prototype racing assets.
# Source: https://kenney.nl/assets/racing-kit
# License: CC0 1.0 Universal (public domain) - no attribution required, commercial use fine.
set -euo pipefail

URL="https://kenney.nl/media/pages/assets/racing-kit/933b8fd9fd-1677580949/kenney_racing-kit.zip"
DEST_DIR="${1:-Assets/GameAssets/Props/KenneyRacingKit}"
DOWNLOAD_DIR="tools/asset-acquisition/downloads"

mkdir -p "$DOWNLOAD_DIR" "$DEST_DIR"
echo "Downloading Kenney Racing Kit from $URL"
curl -fSL -o "$DOWNLOAD_DIR/kenney_racing-kit.zip" "$URL"
unzip -q -o "$DOWNLOAD_DIR/kenney_racing-kit.zip" -d "$DEST_DIR"
echo "Extracted to $DEST_DIR"
echo "Remember to add a license-registry.json entry (license: CC0 1.0, source: $URL)."
