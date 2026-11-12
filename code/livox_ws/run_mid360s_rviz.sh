#!/usr/bin/env bash

set +u

unset AMENT_CURRENT_PREFIX
unset COLCON_CURRENT_PREFIX

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source /opt/ros/humble/setup.bash
source "$SCRIPT_DIR/install/setup.bash"

exec ros2 launch "$SCRIPT_DIR/livox_rviz.launch.py" "$@"
