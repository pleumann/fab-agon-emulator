#!/bin/bash
#
# Rewrites a built fab-agon-emulator binary to load its own private copy of
# libSDL3 via a path relative to the executable (@executable_path), instead
# of the absolute path baked in at build time (e.g. /opt/homebrew/lib,
# /opt/local/lib, or wherever SDL3 happened to live on the build machine).
#
# This makes the resulting binary runnable on any Mac of the same
# architecture regardless of whether - or how - SDL3 is installed there.
# It works no matter which source SDL3 was originally built/found from
# (Homebrew, MacPorts, a manually installed SDL3, the official
# SDL3.xcframework, ...): whatever the binary currently links against is
# simply copied alongside it and re-pointed at the copy.
#
# Usage: bundle-macos-sdl3.sh <path-to-binary>
#   The private copy of libSDL3 is placed next to the binary.

set -euo pipefail

BINARY="${1:?usage: bundle-macos-sdl3.sh <path-to-binary>}"
DEST_DIR="$(dirname "$BINARY")"

if [ ! -f "$BINARY" ]; then
	echo "bundle-macos-sdl3.sh: $BINARY not found" >&2
	exit 1
fi

SDL_LIB=$(otool -L "$BINARY" | awk '/libSDL3[^_].*\.dylib/ {print $1; exit}')

if [ -z "$SDL_LIB" ]; then
	echo "bundle-macos-sdl3.sh: $BINARY does not appear to link against libSDL3" >&2
	exit 1
fi

if [[ "$SDL_LIB" == @* ]]; then
	echo "bundle-macos-sdl3.sh: $BINARY already references SDL3 via a relative path ($SDL_LIB), nothing to do"
	exit 0
fi

SDL_LIB_NAME=$(basename "$SDL_LIB")
DEST_LIB="$DEST_DIR/$SDL_LIB_NAME"

echo "bundle-macos-sdl3.sh: bundling $SDL_LIB -> $DEST_LIB"
cp -f "$SDL_LIB" "$DEST_LIB"
chmod u+w "$DEST_LIB"

install_name_tool -id "@executable_path/$SDL_LIB_NAME" "$DEST_LIB"
install_name_tool -change "$SDL_LIB" "@executable_path/$SDL_LIB_NAME" "$BINARY"

# Modifying the load commands invalidates any existing signature; without
# re-signing, macOS (especially Apple Silicon) will refuse to run the binary.
codesign --force --sign - "$DEST_LIB"
codesign --force --sign - "$BINARY"

echo "bundle-macos-sdl3.sh: done, $BINARY now references:"
otool -L "$BINARY" | grep -i sdl3
