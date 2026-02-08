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

### My hotkeys don't work
1. Ensure you have added yourself to the `input` group. You can do this by running `sudo usermod -aG input $USER` (Then log out and back in).
2. Try restarting your computer if logging out didn't work.
3. Ensure you restart the application after any hotkey changes (A fix is coming soon).

## The download is large due to the packaging of wine within it. This wine is preconfigured with the libraries needed to run livesplit properly

<b>I am not the owner of livesplit. Just a fellow speedrunner :)</b>
Credits to 
- descawed for live-split-hotkeys (https://github.com/descawed/live-split-hotkeys)
- LiveSplit for the original application (https://github.com/LiveSplit/LiveSplit)
