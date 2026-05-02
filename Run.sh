#!/bin/bash

# Get the directory where this script is located
HERE="$(dirname "$(readlink -f "${0}")")"

# --- HELPER: GUI ERROR MESSAGES ---
show_error() {
    if command -v zenity >/dev/null; then
        zenity --error --title="LiveSplit Linux" --text="$1" --width=400
    else
        echo "ERROR: $1"
    fi
}

# --- FAIL-SAFE CLEANUP ---
# This function runs automatically whenever the script exits
cleanup() {
    echo "LiveSplit closed. Cleaning up background processes..."
    # Kill the hotkey bridge directly
    killall hotkeys_bridge 2>/dev/null

    # Exit the script entirely
    exit
}
# Trap the EXIT signal to trigger the cleanup function
trap cleanup EXIT

# --- CONFIGURATION ---
export WINEPREFIX="$HERE/prefix"
export WINEDLLOVERRIDES="winemenubuilder.exe=d;gdiplus=n,b;winhttp=n,b;msxml6=n,b"
export FREETYPE_PROPERTIES="truetype:interpreter-version=35"

# --- PART 1: CHECK PERMISSIONS ---
if ! groups | grep -q "\binput\b"; then
    MSG="<b>Global Hotkeys will not work!</b>\n\nYour user does not have permission to read keyboard inputs.\n\nPlease run this command in a terminal once:\n\n<span foreground='blue'>sudo usermod -aG input \$USER</span>\n\nThen <b>LOG OUT</b> and log back in."
    show_error "$MSG"
    exit 1
fi

# --- PART 2: KEYBOARD AUTO-DETECTION ---
# Collect every keyboard device. by-path exposes the same device under both
# -usb- and -usbv2- aliases, so dedupe by resolved real path.
KBD_ARGS=()
declare -A SEEN_KBD
for link in /dev/input/by-path/*-event-kbd; do
    [ -e "$link" ] || continue
    real=$(readlink -f "$link")
    if [ -z "${SEEN_KBD[$real]}" ]; then
        SEEN_KBD[$real]=1
        KBD_ARGS+=(-d "$real")
    fi
done

# --- PART 3: CHECK SETTINGS ---
if [ ! -f "$HERE/App/settings.cfg" ]; then
    show_error "Settings file not found at App/settings.cfg\n\nLiveSplit will start, but global hotkeys will not work until you save your settings."
fi

# --- PART 3.5: REMOVE STALE OSVERSION OVERRIDE ---
# Older builds of this script forced OSVersion=winxp per-app to dodge a Save
# dialog crash under Wine. That override breaks the WinForms FormClosing event
# chain, so RecentSplits / RecentLayouts / window size / GlobalHotkeysEnabled
# never get persisted on exit. Newer Wine handles IFileDialog correctly, so
# strip the override if a previous run installed it.
"$HERE/wine.AppImage" reg delete 'HKCU\Software\Wine\AppDefaults\LiveSplit.exe' \
    /v Version /f >/dev/null 2>&1

# Populate the user profile with symlinks to the host home so the save dialog
# can enumerate Desktop/Documents/etc. and saves land somewhere the user expects.
PROFILE_DIR="$HERE/prefix/drive_c/users/$USER"
mkdir -p "$PROFILE_DIR"
for d in Desktop Documents Downloads Pictures Music Videos; do
    [ -e "$PROFILE_DIR/$d" ] && continue
    if [ -d "$HOME/$d" ]; then
        ln -sfn "$HOME/$d" "$PROFILE_DIR/$d"
    else
        mkdir -p "$PROFILE_DIR/$d"
    fi
done

# --- PART 4: START LIVESPLIT ---
echo "Starting LiveSplit..."
"$HERE/wine.AppImage" "$HERE/App/LiveSplit.exe" &
LIVESPLIT_PID=$!

# --- PART 5: START BRIDGE LOOP ---
# This loop handles the connection to the TCP server
(
    # Give LiveSplit time to initialize
    sleep 1

    while kill -0 $LIVESPLIT_PID 2>/dev/null; do
        if [ -f "$HERE/App/settings.cfg" ]; then
            # Launch the bridge
            "$HERE/hotkeys_bridge" -s "$HERE/App/settings.cfg" "${KBD_ARGS[@]}"
        fi

        # If we reach here, the bridge disconnected or settings file is missing.
        # Check if LiveSplit is still open before retrying.
        if ! kill -0 $LIVESPLIT_PID 2>/dev/null; then break; fi
        sleep 2
    done
) &

# --- PART 6: WAIT FOR COMPLETION ---
# The script stays alive as long as LiveSplit is running.
# When the user closes LiveSplit, 'wait' finishes, and 'trap' triggers cleanup.
wait $LIVESPLIT_PID
