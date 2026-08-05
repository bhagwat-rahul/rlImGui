#!/usr/bin/env bash
#
# Builds rlImGui as a static library for a single target triple.
# Only raylib headers are required, raylib itself is not built or linked.
#
# Usage:
#   scripts/build-lib.sh <target-triple> [out-dir]
#
# Supported triples:
#   x86_64-apple-darwin          aarch64-apple-darwin
#   x86_64-unknown-linux-gnu     aarch64-unknown-linux-gnu
#   wasm32-unknown-emscripten
#
# Environment overrides:
#   CC            C++ compiler (defaults per triple)
#   AR            archiver (defaults per triple)
#   RAYLIB_DIR    path to raylib sources (default: raylib)
#   IMGUI_DIR     path to imgui sources (default: imgui)
#
# Output: <out-dir>/librlImGui-<target-triple>.a

set -euo pipefail

TRIPLE="${1:?usage: build-lib.sh <target-triple> [out-dir]}"
OUT_DIR="${2:-$(pwd)}"
RAYLIB_DIR="${RAYLIB_DIR:-raylib}"
IMGUI_DIR="${IMGUI_DIR:-imgui}"

for d in "$RAYLIB_DIR" "$IMGUI_DIR"; do
	[[ -d "$d" ]] || {
		echo "error: missing dependency directory '$d' (clone raylib and imgui first)" >&2
		exit 1
	}
done

case "$TRIPLE" in
x86_64-apple-darwin)
	CC="${CC:-clang++}"
	AR="${AR:-ar}"
	ARCH=(-arch x86_64)
	PLATFORM_DEFS=(-DPLATFORM_DESKTOP -DGRAPHICS_API_OPENGL_33)
	;;
aarch64-apple-darwin)
	CC="${CC:-clang++}"
	AR="${AR:-ar}"
	ARCH=(-arch arm64)
	PLATFORM_DEFS=(-DPLATFORM_DESKTOP -DGRAPHICS_API_OPENGL_33)
	;;
x86_64-unknown-linux-gnu)
	CC="${CC:-g++}"
	AR="${AR:-ar}"
	ARCH=(-m64 -fPIC)
	PLATFORM_DEFS=(-DPLATFORM_DESKTOP -DGRAPHICS_API_OPENGL_33)
	;;
aarch64-unknown-linux-gnu)
	CC="${CC:-g++}"
	AR="${AR:-ar}"
	ARCH=(-fPIC)
	PLATFORM_DEFS=(-DPLATFORM_DESKTOP -DGRAPHICS_API_OPENGL_33)
	;;
wasm32-unknown-emscripten)
	CC="${CC:-em++}"
	AR="${AR:-emar}"
	ARCH=()
	PLATFORM_DEFS=(-DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES2)
	;;
*)
	echo "error: unsupported target triple '$TRIPLE'" >&2
	exit 1
	;;
esac

SOURCES=(
	rlImGui.cpp
	"$IMGUI_DIR/imgui.cpp"
	"$IMGUI_DIR/imgui_demo.cpp"
	"$IMGUI_DIR/imgui_draw.cpp"
	"$IMGUI_DIR/imgui_tables.cpp"
	"$IMGUI_DIR/imgui_widgets.cpp"
)

COMMON=(
	-O2 -std=c++17 -DNDEBUG
	-DIMGUI_DISABLE_OBSOLETE_FUNCTIONS -DIMGUI_DISABLE_OBSOLETE_KEYIO
	"${PLATFORM_DEFS[@]}"
)
INCLUDES=(
	-I. -I"$IMGUI_DIR"
	-I"$RAYLIB_DIR/src" -I"$RAYLIB_DIR/src/external"
	-I"$RAYLIB_DIR/src/external/glfw/include"
)

BUILD_DIR="$OUT_DIR/.build-$TRIPLE"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

OBJECTS=()
for src in "${SOURCES[@]}"; do
	obj="$BUILD_DIR/$(basename "$src" .cpp).o"
	"$CC" -c "${COMMON[@]}" "${ARCH[@]}" "${INCLUDES[@]}" "$src" -o "$obj"
	OBJECTS+=("$obj")
done

OUT="$OUT_DIR/librlImGui-$TRIPLE.a"
"$AR" rcs "$OUT" "${OBJECTS[@]}"
rm -rf "$BUILD_DIR"

echo "built $OUT"
