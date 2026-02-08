# LiveSplit Linux Portable

A "one-click" portable wrapper for running the Windows version of LiveSplit on Linux with full Global Hotkey support.

## Features
- **Global Hotkeys:** Works even when LiveSplit isn't focused.
- **Pre-configured:** Includes the necessary Wine prefix for fonts and .NET.
- **No Install:** Just extract and run.

## Setup
1. Download the latest `LiveSplit-Portable-Linux.zip` from the **Releases** tab.
2. Extract the folder.
3. Run the following command once to allow hotkeys:
   `sudo usermod -aG input $USER` (Then log out and back in).
4. Double-click `Run.sh`.
5. In LiveSplit, go to **Control -> Start TCP Server**.

## Troubleshooting
If it doesn't start, ensure you have `zenity` installed for error popups.
If your hotkeys don't work, ensure you have `input` group. Also ensure you restart the application after any hotkey changes (A fix is coming soon).


### I am not the owner of livesplit. Just a fellow speedrunner :)
