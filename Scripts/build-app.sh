#!/usr/bin/env bash
# Builds Ditto.app — a self-contained macOS application bundle.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
CONFIG="${1:-release}"
APP="$ROOT/build/Ditto.app"

echo "▸ Building ($CONFIG)…"
swift build -c "$CONFIG" 2>/dev/null
BIN="$(swift build -c "$CONFIG" --show-bin-path 2>/dev/null)/Ditto"

echo "▸ Assembling bundle…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Ditto"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"

# Icon (best effort — skipped if iconutil/sips unavailable).
if command -v iconutil >/dev/null 2>&1; then
    echo "▸ Rendering icon…"
    swift "$ROOT/Scripts/make-icon.swift" "$ROOT/build" >/dev/null 2>&1 || true
    if [ -d "$ROOT/build/Ditto.iconset" ]; then
        iconutil -c icns "$ROOT/build/Ditto.iconset" -o "$APP/Contents/Resources/Ditto.icns" 2>/dev/null || true
        rm -rf "$ROOT/build/Ditto.iconset"
    fi
fi

# Ad-hoc sign so Accessibility / global hotkey permissions stick to a stable identity.
echo "▸ Signing (ad-hoc)…"
codesign --force --deep --sign - "$APP" 2>/dev/null || echo "  (codesign skipped)"

echo "✓ Built $APP"
