#!/bin/bash
set -euo pipefail

project="$(cd "$(dirname "$0")/.." && pwd)"
build_path="${WAYMARK_BUILD_PATH:-$project/.build}"
destination="${1:-$project/.build/Waymark.app}"
mkdir -p "$build_path" "$(dirname "$destination")"

if [[ -e "$destination" ]]; then
    printf 'Destination already exists: %s\n' "$destination" >&2
    exit 1
fi

args=(--package-path "$project" --scratch-path "$build_path" -c release)
help="$(swift build --help)"
if [[ "$help" == *"-debug-info-format"* ]]; then
    args+=(-debug-info-format none)
fi
if [[ "${WAYMARK_MANIFEST_SANDBOX:-}" == "disabled" ]]; then
    args+=(--disable-sandbox)
fi
swift build "${args[@]}"
binary_dir="$(swift build "${args[@]}" --show-bin-path)"

scratch="$(mktemp -d "$(dirname "$destination")/.waymark.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
app="$scratch/Waymark.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$project/Resources/Info.plist" "$app/Contents/Info.plist"
cp "$binary_dir/Waymark" "$app/Contents/MacOS/Waymark"

swiftc -module-cache-path "$build_path/icon-cache" "$project/Scripts/draw-icon.swift" -o "$scratch/draw-icon"
"$scratch/draw-icon" "$app/Contents/Resources/Waymark.icns"
codesign --force --sign - "$app"
codesign --verify --strict "$app"
mv "$app" "$destination"
printf '%s\n' "$destination"
