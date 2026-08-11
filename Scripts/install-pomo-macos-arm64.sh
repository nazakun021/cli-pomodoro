#!/bin/sh
set -eu

RELEASE_BASE="https://github.com/nazakun021/cli-pomodoro/releases/latest/download"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

case "$(uname -m)" in
    arm64) ;;
    *) printf '%s\n' "This installer is for Apple Silicon Macs." >&2; exit 2 ;;
esac

ARCHIVE="$TEMP_DIR/Pomo-macos-arm64.zip"
curl --fail --location --show-error --silent "$RELEASE_BASE/Pomo-macos-arm64.zip" -o "$ARCHIVE"
ditto -x -k "$ARCHIVE" "$TEMP_DIR"

APP_DIR="$HOME/Applications"
APP_PATH="$APP_DIR/Pomo.app"
mkdir -p "$APP_DIR" "$HOME/.local/bin"
rm -rf "$APP_PATH"
ditto "$TEMP_DIR/Pomo.app" "$APP_PATH"
ln -sfn "$APP_PATH/Contents/Resources/pomo" "$HOME/.local/bin/pomo"
open "$APP_PATH"

printf '%s\n' "Pomo installed at $APP_PATH"
printf '%s\n' "CLI installed at $HOME/.local/bin/pomo"
printf '%s\n' "Add $HOME/.local/bin to PATH if the pomo command is not found."
