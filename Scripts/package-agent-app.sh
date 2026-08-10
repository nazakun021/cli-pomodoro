#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CONFIG=${1:-release}
OUTPUT=${2:-"$ROOT/.build/$CONFIG/Pomo.app"}
ARCHES=${POMO_ARCHES:-arm64}

case "$ROOT" in
	*" "*) printf '%s\n' "Repository paths containing spaces are unsupported" >&2; exit 2 ;;
esac

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

AGENT_INPUTS=""
CLI_INPUTS=""
ARCH_COUNT=0
SINGLE_ARCH=""
SEEN_ARCHES=""
for arch in $ARCHES; do
	case "$arch" in
		arm64|x86_64) ;;
		*) printf '%s\n' "Unsupported architecture: $arch" >&2; exit 2 ;;
	esac
	case " $SEEN_ARCHES " in
		*" $arch "*) printf '%s\n' "Duplicate architecture: $arch" >&2; exit 2 ;;
	esac
	SEEN_ARCHES="$SEEN_ARCHES $arch"
	ARCH_COUNT=$((ARCH_COUNT + 1))
	SINGLE_ARCH="$arch"
	swift build --package-path "$ROOT" --configuration "$CONFIG" --arch "$arch" --product PomoAgent
	swift build --package-path "$ROOT" --configuration "$CONFIG" --arch "$arch" --product pomo
	AGENT_INPUT="$ROOT/.build/${arch}-apple-macosx/$CONFIG/PomoAgent"
	CLI_INPUT="$ROOT/.build/${arch}-apple-macosx/$CONFIG/pomo"
	case " $(lipo -archs "$AGENT_INPUT") " in
		*" $arch "*) ;;
		*) printf '%s\n' "Agent binary lacks requested architecture: $arch" >&2; exit 2 ;;
	esac
	case " $(lipo -archs "$CLI_INPUT") " in
		*" $arch "*) ;;
		*) printf '%s\n' "CLI binary lacks requested architecture: $arch" >&2; exit 2 ;;
	esac
	AGENT_INPUTS="$AGENT_INPUTS $AGENT_INPUT"
	CLI_INPUTS="$CLI_INPUTS $CLI_INPUT"
done
if [ "$ARCH_COUNT" -eq 0 ]; then
	printf '%s\n' "POMO_ARCHES must contain at least one architecture" >&2
	exit 2
fi
mkdir -p "$ROOT/.build/$CONFIG"
if [ "$ARCH_COUNT" -eq 1 ]; then
	AGENT_BINARY="$ROOT/.build/${SINGLE_ARCH}-apple-macosx/$CONFIG/PomoAgent"
	CLI_BINARY="$ROOT/.build/${SINGLE_ARCH}-apple-macosx/$CONFIG/pomo"
else
	AGENT_BINARY="$ROOT/.build/$CONFIG/PomoAgent"
	CLI_BINARY="$ROOT/.build/$CONFIG/pomo"
	lipo -create $AGENT_INPUTS -output "$AGENT_BINARY"
	lipo -create $CLI_INPUTS -output "$CLI_BINARY"
fi
rm -rf "$OUTPUT"
mkdir -p "$OUTPUT/Contents/MacOS" "$OUTPUT/Contents/Resources"
cp "$AGENT_BINARY" "$OUTPUT/Contents/MacOS/PomoAgent"
cp "$CLI_BINARY" "$OUTPUT/Contents/Resources/pomo"
cp "$ROOT/Resources/PomoAgent/Info.plist" "$OUTPUT/Contents/Info.plist"
chmod 755 "$OUTPUT/Contents/MacOS/PomoAgent"
codesign --force --deep --sign - --options runtime "$OUTPUT"
codesign --verify --deep --strict "$OUTPUT"

printf '%s\n' "$OUTPUT"
