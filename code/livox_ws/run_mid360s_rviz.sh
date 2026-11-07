#!/usr/bin/env bash

set +u

unset AMENT_CURRENT_PREFIX
unset COLCON_CURRENT_PREFIX

source /opt/ros/humble/setup.bash
source /home/shaun/static/tools/livox_ws/install/setup.bash

exec ros2 launch livox_ros_driver2 rviz_MID360s_launch.py "$@"
