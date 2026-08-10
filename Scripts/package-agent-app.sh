#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CONFIG=${1:-release}
OUTPUT=${2:-"$ROOT/.build/$CONFIG/Pomo.app"}

case "$OUTPUT" in
	*.app) ;;
	*) printf '%s\n' "Output must be an app bundle path ending in .app" >&2; exit 2 ;;
esac
case "$OUTPUT" in
	/|"$HOME"|"$ROOT") printf '%s\n' "Refusing to remove unsafe output path" >&2; exit 2 ;;
esac
OUTPUT_PARENT=$(CDPATH= cd -- "$(dirname -- "$OUTPUT")" 2>/dev/null && pwd) || {
	printf '%s\n' "Output parent must already exist" >&2
	exit 2
}
OUTPUT="$OUTPUT_PARENT/$(basename -- "$OUTPUT")"
case "$OUTPUT" in
	"$ROOT/.build/"*.app|/tmp/*.app) ;;
	*) printf '%s\n' "Output must be under .build or /tmp" >&2; exit 2 ;;
esac

swift build --package-path "$ROOT" --configuration "$CONFIG" --product PomoAgent
rm -rf "$OUTPUT"
mkdir -p "$OUTPUT/Contents/MacOS" "$OUTPUT/Contents/Resources"
cp "$ROOT/.build/$CONFIG/PomoAgent" "$OUTPUT/Contents/MacOS/PomoAgent"
cp "$ROOT/Resources/PomoAgent/Info.plist" "$OUTPUT/Contents/Info.plist"
chmod 755 "$OUTPUT/Contents/MacOS/PomoAgent"
codesign --force --deep --sign - --options runtime "$OUTPUT"
codesign --verify --deep --strict "$OUTPUT"

printf '%s\n' "$OUTPUT"
