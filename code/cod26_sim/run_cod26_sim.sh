#!/usr/bin/env bash

set +u

SIM="/home/shaun/static/tools/cod26_ws/sim"
WS26="/home/shaun/static/tools/cod26_ws"
WSCOD="/home/shaun/static/tools/cod_ws"
MAP="$WS26/install/cod_bringup/share/cod_bringup/maps/rmul2026.yaml"
PARAMS="$SIM/config/sim_singlenav2_params.yaml"
LIO_CONFIG="$SIM/config/mid360_sim.yaml"
LOG_DIR="$SIM/logs/sim_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOG_DIR"

source /opt/ros/humble/setup.bash
source "$WSCOD/install/setup.bash"
source "$WS26/install/setup.bash"
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
  echo "停止 2026 仿真..."
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
  pkill -x small_point_lio 2>/dev/null || true
  pkill -x lidar_filter_node 2>/dev/null || true
  pkill -x fake_vel_transfor 2>/dev/null || true
  pkill -x relay 2>/dev/null || true
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
echo "[1/7] 启动 Gazebo + 2026 场地 + 哨兵..."
start_bg gazebo ros2 launch "$SIM/launch/gazebo_rmul2026.launch.py"
wait_topic /clock 60 || { echo "Gazebo 启动失败"; exit 1; }
wait_topic /livox/lidar 60 || { echo "/livox/lidar 没有数据"; exit 1; }
wait_topic /livox/imu 60 || { echo "/livox/imu 没有数据"; exit 1; }

echo "[2/7] 发布 base_link -> chassis 和 map -> odom..."
start_bg base_link_chassis ros2 run tf2_ros static_transform_publisher \
  --x 0 --y 0 --z 0 --roll 0 --pitch 0 --yaw 0 \
  --frame-id base_link --child-frame-id chassis \
  --ros-args -p use_sim_time:=true
start_bg map_odom ros2 run tf2_ros static_transform_publisher \
  --x -0.181 --y -2.611 --z 0 --roll 0 --pitch 0 --yaw 0 \
  --frame-id map --child-frame-id odom \
  --ros-args -p use_sim_time:=true

echo "[3/7] 启动 Small Point-LIO..."
start_bg livox_fix python3 "$SIM/tools/livox_timebase_fix.py"
sleep 1
start_bg point_lio ros2 run small_point_lio small_point_lio_node \
  --ros-args --params-file "$LIO_CONFIG" -p use_sim_time:=true
wait_topic /Odometry 90 || { echo "/Odometry 没有数据"; exit 1; }

echo "[4/7] 启动点云过滤和速度转换..."
start_bg lidar_filter ros2 run cpp_lidar_filter lidar_filter_node \
  --ros-args \
  -p input_topic:=/livox/lidar/pointcloud \
  -p output_topic:=/livox/lidar_filtered \
  -p min_x:=-0.2 -p max_x:=0.2 \
  -p min_y:=-0.2 -p max_y:=0.4 \
  -p min_z:=-0.1 -p max_z:=0.2 \
  -p negative:=true -p leaf_size:=0.05
start_bg fake_vel ros2 run fake_vel_transform fake_vel_transform_node \
  --ros-args -p use_sim_time:=true \
  -p robot_base_frame:=base_link \
  -p fake_robot_base_frame:=base_link_fake \
  -p odom_topic:=Odometry \
  -p input_cmd_vel_topic:=cmd_vel \
  -p output_cmd_vel_topic:=aft_cmd_vel
start_bg cmd_relay ros2 run topic_tools relay /aft_cmd_vel /cmd_vel_sim
wait_topic /livox/lidar_filtered 30 || { echo "/livox/lidar_filtered 没有数据"; exit 1; }

echo "[5/7] 启动 map_server..."
start_bg localization ros2 launch "$WS26/install/cod_bringup/share/cod_bringup/launch/localization_launch.py" \
  map:="$MAP" use_sim_time:=true params_file:="$PARAMS" autostart:=False use_composition:=False
wait_node /map_server 60 || { echo "map_server 未启动"; exit 1; }
set_state /map_server || exit 1

echo "[6/7] 启动 Nav2..."
start_bg nav2 ros2 launch "$WS26/install/cod_bringup/share/cod_bringup/launch/navigation_launch.py" \
  use_sim_time:=true params_file:="$PARAMS" autostart:=False use_composition:=False
for node in /controller_server /smoother_server /planner_server /behavior_server /bt_navigator /waypoint_follower /velocity_smoother; do
  wait_node "$node" 60 || { echo "节点未启动: $node"; exit 1; }
done
for node in /controller_server /smoother_server /planner_server /behavior_server /bt_navigator /waypoint_follower /velocity_smoother; do
  set_state "$node" || exit 1
done

echo "Nav2 状态:"
for node in /map_server /controller_server /smoother_server /planner_server /behavior_server /bt_navigator /waypoint_follower /velocity_smoother; do
  printf '  %-24s ' "$node"
  timeout 3 ros2 lifecycle get "$node" 2>/dev/null | head -1
done

if [[ "${NO_RVIZ:-0}" != "1" ]]; then
  echo "[7/7] 启动 RViz..."
  start_bg rviz rviz2 -d "$WS26/install/cod_bringup/share/cod_bringup/rviz/cod_nav.rviz"
fi

echo
echo "2026 COD 仿真已启动。"
echo "发送单点目标:"
echo "  ros2 action send_goal /navigate_to_pose nav2_msgs/action/NavigateToPose \"{pose: {header: {frame_id: 'map'}, pose: {position: {x: 1.0, y: 0.0, z: 0.0}, orientation: {x: 0.0, y: 0.0, z: 0.0, w: 1.0}}}}\""
echo "日志: $LOG_DIR"
echo "按 Ctrl+C 停止。"

wait
