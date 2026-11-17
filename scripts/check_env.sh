#!/usr/bin/env bash
# Check host dependencies and the current rm_sim install tree.
set +e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0
WARN=0

ok()   { printf '[ OK ] %s\n' "$*"; }
bad()  { printf '[FAIL] %s\n' "$*"; FAIL=$((FAIL + 1)); }
warn() { printf '[WARN] %s\n' "$*"; WARN=$((WARN + 1)); }

echo "=== host ==="
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  echo "OS: ${PRETTY_NAME:-unknown}"
fi
echo "User: $(id -un)"
echo "Root: $ROOT"

set +u
source /opt/ros/humble/setup.bash 2>/dev/null

for cmd in ros2 colcon gzserver rviz2 python3 gio; do
  if command -v "$cmd" >/dev/null 2>&1; then ok "command: $cmd"; else bad "command missing: $cmd"; fi
done

if [[ "${ROS_DISTRO:-}" == "humble" ]]; then ok "ROS_DISTRO=humble"; else bad "ROS_DISTRO is not humble"; fi

echo
echo "=== apt / ROS packages ==="
for pkg in \
  gazebo_ros gazebo_plugins robot_state_publisher joint_state_publisher xacro \
  nav2_bringup nav2_controller nav2_planner nav2_bt_navigator nav2_lifecycle_manager \
  pcl_ros pcl_conversions tf2_ros tf2_geometry_msgs rqt_gui_py; do
  if ros2 pkg prefix "$pkg" >/dev/null 2>&1; then ok "ros package: $pkg"; else bad "ros package missing: $pkg"; fi
done

if ros2 pkg prefix realsense2_camera >/dev/null 2>&1; then
  ok "ros package: realsense2_camera"
else
  warn "realsense2_camera missing; cod_bringup/singlenav_launch.py includes it"
fi

echo
echo "=== Python ==="
if python3 -c 'import yaml' 2>/dev/null; then ok "python3: yaml"; else bad "python3: PyYAML missing"; fi
if python3 -c 'import PyQt5' 2>/dev/null; then ok "python3: PyQt5"; else bad "python3: PyQt5 missing"; fi

echo
echo "=== rm_sim install tree ==="
if [[ -f "$ROOT/scripts/setup_split.sh" ]]; then
  set +u
  source "$ROOT/scripts/setup_split.sh" 2>/dev/null
  for pkg in fast_lio small_point_lio livox_ros_driver2 nav_bringup cod_bringup cod_serial_ul26 pcd2pgm pointcloud_to_laserscan; do
    if ros2 pkg prefix "$pkg" >/dev/null 2>&1; then ok "workspace package: $pkg"; else bad "workspace package missing: $pkg"; fi
  done
else
  bad "scripts/setup_split.sh missing"
fi

echo
echo "=== hardware (optional) ==="
if [[ -e /dev/ttyACM0 ]]; then
  ls -l /dev/ttyACM0
  if id -nG "$USER" | grep -qw dialout; then ok "user in dialout"; else warn "user not in dialout; run: sudo usermod -aG dialout $USER"; fi
else
  warn "/dev/ttyACM0 not present (only needed for real lower-board serial)"
fi
if command -v ip >/dev/null 2>&1; then ip -br addr | grep -E '192\.168\.1\.50|enx|usb' || warn "no 192.168.1.50 USB network interface"
fi

echo
echo "结果: $FAIL errors, $WARN warnings"
[[ "$FAIL" -eq 0 ]]
