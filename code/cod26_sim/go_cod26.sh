#!/usr/bin/env bash

if [[ $# -lt 2 ]]; then
  echo "用法: $0 <map_x> <map_y> [yaw_deg]"
  echo "示例: $0 4.6 -5.5 0"
  exit 1
fi

X="$1"
Y="$2"
YAW_DEG="${3:-0}"

read -r QZ QW < <(
  python3 -c "import math; a=math.radians(float('$YAW_DEG'))/2; print(math.sin(a), math.cos(a))"
)

source /opt/ros/humble/setup.bash
source /home/shaun/static/tools/cod_ws/install/setup.bash
source /home/shaun/static/tools/cod26_ws/install/setup.bash

ros2 action send_goal /navigate_to_pose nav2_msgs/action/NavigateToPose \
  "{pose: {header: {frame_id: 'map'}, pose: {position: {x: $X, y: $Y, z: 0.0}, orientation: {x: 0.0, y: 0.0, z: $QZ, w: $QW}}}}" \
  --feedback
