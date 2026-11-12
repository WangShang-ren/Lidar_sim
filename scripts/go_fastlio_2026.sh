#!/usr/bin/env bash
set -e
if [[ $# -lt 2 ]]; then echo "用法: $0 <x> <y> [yaw_deg]"; exit 1; fi
X="$1"; Y="$2"; YAW="${3:-0}"
read -r QZ QW < <(python3 -c "import math; a=math.radians(float('$YAW'))/2; print(math.sin(a), math.cos(a))")
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/scripts/setup_split.sh"
exec ros2 action send_goal /navigate_to_pose nav2_msgs/action/NavigateToPose "{pose: {header: {frame_id: 'map'}, pose: {position: {x: $X, y: $Y, z: 0.0}, orientation: {x: 0.0, y: 0.0, z: $QZ, w: $QW}}}}" --feedback
