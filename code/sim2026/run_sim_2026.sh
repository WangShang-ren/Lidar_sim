#!/usr/bin/env bash

WS="/home/shaun/static/tools/cod_ws"
MAP="$WS/sim2026/maps/rmul2026.yaml"
LOG_DIR="$WS/log/sim_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOG_DIR"

source /opt/ros/humble/setup.bash
source "$WS/install/setup.bash"
export RCUTILS_LOGGING_BUFFERED_STREAM=1

PIDS=()
LAST_PID=""

start_bg() {
  local name=$1
  shift
  "$@" >"$LOG_DIR/$name.log" 2>&1 &
  LAST_PID=$!
  PIDS+=("$LAST_PID")
}

wait_topic() {
  local topic=$1
  local seconds=${2:-30}
  local i
  for ((i = 0; i < seconds; i++)); do
    if timeout 2 ros2 topic echo "$topic" --once >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

wait_node() {
  local node=$1
  local seconds=${2:-30}
  local i
  for ((i = 0; i < seconds; i++)); do
    if ros2 node list 2>/dev/null | grep -qx "$node"; then
      return 0
    fi
    sleep 1
  done
  return 1
}

set_state() {
  local node=$1
  local state=""
  local i
  for ((i = 0; i < 20; i++)); do
    state=$(timeout 3 ros2 lifecycle get "$node" 2>/dev/null | awk '{print $1}')
    if [[ -n "$state" ]]; then
      break
    fi
    sleep 1
  done
  case "$state" in
    active)
      return 0
      ;;
    unconfigured)
      timeout 10 ros2 lifecycle set "$node" configure >/dev/null 2>&1 || return 1
      timeout 10 ros2 lifecycle set "$node" activate >/dev/null 2>&1 || return 1
      ;;
    inactive)
      timeout 10 ros2 lifecycle set "$node" activate >/dev/null 2>&1 || return 1
      ;;
    *)
      echo "unknown state for $node: '$state'"
      return 1
      ;;
  esac
}

cleanup() {
  echo
  echo "停止仿真..."
  local pid
  for pid in "${PIDS[@]}"; do
    kill -TERM "$pid" 2>/dev/null || true
  done
  sleep 2
  for pid in "${PIDS[@]}"; do
    kill -KILL "$pid" 2>/dev/null || true
  done
  pkill -x gzserver 2>/dev/null || true
  pkill -x gzclient 2>/dev/null || true
  pkill -x fastlio_mapping 2>/dev/null || true
  pkill -x pointcloud_to_l 2>/dev/null || true
  pkill -x robot_state_pub 2>/dev/null || true
  pkill -x joint_state_pub 2>/dev/null || true
  pkill -x static_transfor 2>/dev/null || true
  pkill -x rviz2 2>/dev/null || true
  pkill -x map_server 2>/dev/null || true
  pkill -x controller_serv 2>/dev/null || true
  pkill -x smoother_server 2>/dev/null || true
  pkill -x planner_server 2>/dev/null || true
  pkill -x behavior_server 2>/dev/null || true
  pkill -x bt_navigator 2>/dev/null || true
  pkill -x waypoint_follow 2>/dev/null || true
  pkill -x velocity_smooth 2>/dev/null || true
  pkill -x lifecycle_manag 2>/dev/null || true
}

trap cleanup INT TERM EXIT

echo "日志目录: $LOG_DIR"
echo "[1/5] 启动 Gazebo + Livox + 哨兵..."
start_bg gazebo ros2 launch "$WS/sim2026/launch/gazebo_rmul2026_cod.launch.py"
GAZEBO_PID=$LAST_PID
wait_topic /clock 60 || { echo "Gazebo 启动失败"; exit 1; }
wait_topic /livox/lidar 60 || { echo "Livox 没有数据"; exit 1; }

echo "[2/5] 启动 FAST-LIO + /scan..."
start_bg fastlio ros2 launch "$WS/sim2026/launch/sim_lio_only_2026.launch.py"
LIO_PID=$LAST_PID
wait_topic /scan 60 || { echo "/scan 没有数据"; exit 1; }
wait_topic /Odometry 60 || { echo "/Odometry 没有数据"; exit 1; }

echo "[3/5] 启动 chassis -> chassis_fake 和 map -> odom TF..."
start_bg chassis_fake ros2 run tf2_ros static_transform_publisher \
  --x 0 --y 0 --z 0 --roll 0 --pitch 0 --yaw 0 \
  --frame-id chassis --child-frame-id chassis_fake \
  --ros-args -p use_sim_time:=true
TF_PID=$LAST_PID
start_bg map_odom ros2 run tf2_ros static_transform_publisher \
  --x -0.181 --y -2.611 --z 0 --roll 0 --pitch 0 --yaw 0 \
  --frame-id map --child-frame-id odom \
  --ros-args -p use_sim_time:=true
MAP_ODOM_PID=$LAST_PID

echo "[4/5] 启动 Nav2..."
start_bg nav2 ros2 launch "$WS/install/nav_bringup/share/nav_bringup/launch/simulation/sim_nav_bringup.launch.py" \
  map:="$MAP" use_sim_time:=true params_file:="$WS/sim2026/params/sim_nav2_params_2026.yaml" use_composition:=False autostart:=False
NAV_PID=$LAST_PID

for node in /map_server /controller_server /smoother_server /planner_server /behavior_server /bt_navigator /waypoint_follower /velocity_smoother; do
  wait_node "$node" 60 || { echo "节点未启动: $node"; exit 1; }
done

echo "[5/5] 激活 Nav2 lifecycle..."
set_state /map_server || exit 1
set_state /controller_server || exit 1
set_state /smoother_server || exit 1
set_state /planner_server || exit 1
set_state /behavior_server || exit 1
set_state /bt_navigator || exit 1
set_state /waypoint_follower || exit 1
set_state /velocity_smoother || exit 1

echo "Nav2 状态:"
for node in /map_server /controller_server /smoother_server /planner_server /behavior_server /bt_navigator /waypoint_follower /velocity_smoother; do
  printf '  %-24s ' "$node"
  timeout 3 ros2 lifecycle get "$node" 2>/dev/null | head -1
done

if [[ "${NO_RVIZ:-0}" != "1" ]]; then
  echo "启动 RViz..."
  start_bg rviz rviz2 -d "$WS/install/nav_bringup/share/nav_bringup/rviz/cod_nav.rviz"
  RVIZ_PID=$LAST_PID
fi

echo
echo "仿真已启动。"
echo "发送导航目标:"
echo "  ros2 action send_goal /navigate_to_pose nav2_msgs/action/NavigateToPose \"{pose: {header: {frame_id: 'map'}, pose: {position: {x: 4.6, y: -5.5, z: 0.0}, orientation: {x: 0.0, y: 0.0, z: 0.0, w: 1.0}}}}\""
echo "按 Ctrl+C 停止。"

wait
