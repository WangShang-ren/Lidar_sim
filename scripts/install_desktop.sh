#!/usr/bin/env bash
# Generate and install the LIO-Tuner desktop entry for the current checkout.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENTRY="$ROOT/LIO-Tuner.desktop"
cat > "$ENTRY" <<DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=LIO Tuner
Comment=Start lidar/simulation and tune FAST-LIO / Point-LIO
Exec=$ROOT/scripts/run_lio_tune_gui.sh
Path=$ROOT
Icon=utilities-system-monitor
Terminal=false
StartupNotify=true
Categories=Development;Robotics;
DESKTOP
chmod +x "$ENTRY"
mkdir -p "$HOME/Desktop" "$HOME/.local/share/applications"
cp "$ENTRY" "$HOME/Desktop/LIO-Tuner.desktop"
cp "$ENTRY" "$HOME/.local/share/applications/LIO-Tuner.desktop"
chmod +x "$HOME/Desktop/LIO-Tuner.desktop" "$HOME/.local/share/applications/LIO-Tuner.desktop"
gio set "$HOME/Desktop/LIO-Tuner.desktop" metadata::trusted true 2>/dev/null || true
echo "installed: $HOME/Desktop/LIO-Tuner.desktop"
echo "installed: $HOME/.local/share/applications/LIO-Tuner.desktop"
