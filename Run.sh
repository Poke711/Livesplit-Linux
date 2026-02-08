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
    # Remove the temporary shadow config
    rm "$HERE/App/bridge_settings.tmp" 2>/dev/null
    # Exit the script entirely
    exit
}
# Trap the EXIT signal to trigger the cleanup function
trap cleanup EXIT

# --- CONFIGURATION ---
export WINEPREFIX="$HERE/prefix"
export WINEDLLOVERRIDES="winemenubuilder.exe=d"
export FREETYPE_PROPERTIES="truetype:interpreter-version=35"

# --- PART 1: CHECK PERMISSIONS ---
if ! groups | grep -q "\binput\b"; then
    MSG="<b>Global Hotkeys will not work!</b>\n\nYour user does not have permission to read keyboard inputs.\n\nPlease run this command in a terminal once:\n\n<span foreground='blue'>sudo usermod -aG input \$USER</span>\n\nThen <b>LOG OUT</b> and log back in."
    show_error "$MSG"
    exit 1
fi

# --- PART 2: KEYBOARD AUTO-DETECTION ---
PRIMARY_KBD=$(ls /dev/input/by-path/*-event-kbd 2>/dev/null | head -n 1)
KBD_ARG=""
if [ -n "$PRIMARY_KBD" ]; then
    KBD_ARG="-d $PRIMARY_KBD"
fi

# --- PART 3: CREATE SHADOW CONFIG ---
if [ ! -f "$HERE/App/settings.cfg" ]; then
    show_error "Settings file not found at App/settings.cfg\n\nPlease run LiveSplit and save your settings first."
    exit 1
fi
cp "$HERE/App/settings.cfg" "$HERE/App/bridge_settings.tmp"
sed -i 's/<GlobalHotkeysEnabled>False<\/GlobalHotkeysEnabled>/<GlobalHotkeysEnabled>True<\/GlobalHotkeysEnabled>/g' "$HERE/App/bridge_settings.tmp"

# --- PART 4: START LIVESPLIT ---
echo "Starting LiveSplit..."
"$HERE/wine.AppImage" "$HERE/App/LiveSplit.exe" &
LIVESPLIT_PID=$!

# --- PART 5: START BRIDGE LOOP ---
# This loop handles the connection to the TCP server
(
    # Give LiveSplit time to initialize
    sleep 4

    while kill -0 $LIVESPLIT_PID 2>/dev/null; do
        # Launch the bridge
        "$HERE/hotkeys_bridge" -s "$HERE/App/bridge_settings.tmp" $KBD_ARG

        # If we reach here, the bridge disconnected.
        # Check if LiveSplit is still open before retrying.
        if ! kill -0 $LIVESPLIT_PID 2>/dev/null; then break; fi
        sleep 2
    done
) &

# --- PART 6: WAIT FOR COMPLETION ---
# The script stays alive as long as LiveSplit is running.
# When the user closes LiveSplit, 'wait' finishes, and 'trap' triggers cleanup.
wait $LIVESPLIT_PID
