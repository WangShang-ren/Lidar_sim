#!/usr/bin/env bash
# Install host dependencies for rm_sim on Ubuntu 22.04 + ROS 2 Humble.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WITH_REALSENSE=1
WITH_LIVOX_SDK=1

for arg in "$@"; do
  case "$arg" in
    --no-realsense) WITH_REALSENSE=0 ;;
    --no-livox-sdk) WITH_LIVOX_SDK=0 ;;
    -h|--help)
      echo "用法: $0 [--no-realsense] [--no-livox-sdk]"
      exit 0
      ;;
    *) echo "未知参数: $arg"; exit 1 ;;
  esac
done

if ! command -v ros2 >/dev/null 2>&1 || [[ "${ROS_DISTRO:-}" != "humble" ]]; then
  echo "错误: 未检测到 ROS 2 Humble。"
  echo "请先安装 Ubuntu 22.04 的 ROS 2 Humble Desktop："
  echo "https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debians.html"
  exit 1
fi

echo "=== apt update ==="
sudo apt update

echo "=== ROS 2 / Gazebo / Nav2 / PCL ==="
sudo apt install -y \
  ros-humble-desktop \
  ros-humble-navigation2 \
  ros-humble-nav2-bringup \
  ros-humble-gazebo-ros-pkgs \
  ros-humble-gazebo-plugins \
  ros-humble-topic-tools \
  ros-humble-xacro \
  ros-humble-joint-state-publisher \
  ros-humble-robot-state-publisher \
  ros-humble-pcl-ros \
  ros-humble-pcl-conversions \
  ros-humble-pointcloud-to-laserscan \
  ros-humble-tf2-ros \
  ros-humble-tf2-geometry-msgs \
  ros-humble-rqt-gui \
  ros-humble-rqt-gui-py \
  ros-humble-rqt-py-common \
  python3-colcon-common-extensions \
  python3-rosdep \
  python3-pyqt5 \
  python3-yaml \
  gazebo \
  libpcl-dev \
  libeigen3-dev \
  libboost-all-dev \
  libapr1-dev \
  libyaml-cpp-dev \
  libusb-1.0-0-dev \
  cmake \
  build-essential \
  git

if [[ "$WITH_REALSENSE" -eq 1 ]]; then
  echo "=== RealSense (singlenav_launch.py includes it) ==="
  sudo apt install -y ros-humble-realsense2-camera
fi

if [[ "$WITH_LIVOX_SDK" -eq 1 ]]; then
  echo "=== Livox-SDK2 ==="
  if [[ ! -d "$ROOT/third_party/Livox-SDK2" ]]; then
    echo "错误: 找不到 $ROOT/third_party/Livox-SDK2"
    echo "请先复制 third_party 源码。"
    exit 1
  fi
  cmake -S "$ROOT/third_party/Livox-SDK2" -B "$ROOT/third_party/Livox-SDK2/build" \
    -DCMAKE_BUILD_TYPE=Release
  cmake --build "$ROOT/third_party/Livox-SDK2/build" -j"$(nproc)"
  sudo cmake --install "$ROOT/third_party/Livox-SDK2/build"
  sudo ldconfig
fi

echo
echo "=== 串口权限 ==="
if id -nG "$USER" | grep -qw dialout; then
  echo "用户已在 dialout 组。"
else
  echo "正在把 $USER 加入 dialout 组；重新登录后生效。"
  sudo usermod -aG dialout "$USER"
fi

echo
echo "依赖安装完成。"
echo "下一步:"
echo "  cd $ROOT"
echo "  scripts/check_env.sh"
echo "  scripts/build_all.sh"
