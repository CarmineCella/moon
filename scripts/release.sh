#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------------------------
# Usage
#   ./scripts/release.sh v0.51
#
# Optional environment variables:
#   CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
#   ZIP_NAME="custom_name.zip"
# ------------------------------------------------------------------------------

if [ $# -lt 1 ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

VERSION="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$ROOT_DIR/$VERSION"
ZIP_NAME="${ZIP_NAME:-$VERSION.zip}"

CLI_SRC="$ROOT_DIR/build/cli/musil"
IDE_SRC="$ROOT_DIR/build/ide/Musil IDE.app"
SRC_DIR="$ROOT_DIR/src"
DOCS_DIR="$ROOT_DIR/docs"
EXAMPLES_DIR="$ROOT_DIR/examples"
DATA_DIR="$ROOT_DIR/data"

echo "Creating release folder: $OUT_DIR"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

# ------------------------------------------------------------------------------
# Copy CLI
# ------------------------------------------------------------------------------

if [ ! -f "$CLI_SRC" ]; then
    echo "ERROR: CLI not found at: $CLI_SRC"
    exit 1
fi

echo "Copying CLI..."
mkdir -p "$OUT_DIR/bin"
cp "$CLI_SRC" "$OUT_DIR/bin/musil"

if command -v strip >/dev/null 2>&1; then
    echo "Stripping CLI binary..."
    strip "$OUT_DIR/bin/musil" || echo "Warning: strip failed, continuing."
else
    echo "Warning: strip not found, skipping."
fi

# ------------------------------------------------------------------------------
# Copy IDE app
# ------------------------------------------------------------------------------

if [ -d "$IDE_SRC" ]; then
    echo "Copying IDE app..."
    cp -R "$IDE_SRC" "$OUT_DIR/"
else
    echo "Warning: IDE app not found at: $IDE_SRC"
fi

# ------------------------------------------------------------------------------
# Copy .mu files
# ------------------------------------------------------------------------------

echo "Copying .mu files..."
mkdir -p "$OUT_DIR/src"
if compgen -G "$SRC_DIR/*.mu" >/dev/null; then
    cp "$SRC_DIR"/*.mu "$OUT_DIR/src/"
else
    echo "Warning: no .mu files found in $SRC_DIR"
fi

# ------------------------------------------------------------------------------
# Copy PDFs
# ------------------------------------------------------------------------------

echo "Copying docs..."
mkdir -p "$OUT_DIR/docs"
if compgen -G "$DOCS_DIR/*.pdf" >/dev/null; then
    cp "$DOCS_DIR"/*.pdf "$OUT_DIR/docs/"
else
    echo "Warning: no .pdf files found in $DOCS_DIR"
fi

# ------------------------------------------------------------------------------
# Copy examples and data recursively
# ------------------------------------------------------------------------------

if [ -d "$EXAMPLES_DIR" ]; then
    echo "Copying examples..."
    cp -R "$EXAMPLES_DIR" "$OUT_DIR/"
else
    echo "Warning: examples directory not found."
fi

if [ -d "$DATA_DIR" ]; then
    echo "Copying data..."
    cp -R "$DATA_DIR" "$OUT_DIR/"
else
    echo "Warning: data directory not found."
fi

# ------------------------------------------------------------------------------
# Codesign app on macOS if identity is provided
# ------------------------------------------------------------------------------

if [[ "$OSTYPE" == darwin* ]]; then
    APP_DST="$OUT_DIR/Musil IDE.app"
    if [ -d "$APP_DST" ]; then
        if [ -n "${CODESIGN_IDENTITY:-}" ]; then
            if command -v codesign >/dev/null 2>&1; then
                echo "Codesigning app with identity: $CODESIGN_IDENTITY"
                codesign --force --deep --sign "$CODESIGN_IDENTITY" "$APP_DST"
            else
                echo "Warning: codesign not found, skipping."
            fi
        else
            echo "No CODESIGN_IDENTITY provided, skipping codesign."
        fi
    fi
fi

# ------------------------------------------------------------------------------
# Create zip
# ------------------------------------------------------------------------------

echo "Creating zip archive: $ZIP_NAME"
cd "$ROOT_DIR"
rm -f "$ZIP_NAME"
zip -r "$ZIP_NAME" "$VERSION"

echo
echo "Release package created:"
echo "  Folder: $OUT_DIR"
echo "  Zip:    $ROOT_DIR/$ZIP_NAME"