# rm_sim 迁移到另一台机器

## 1. 能不能直接复制整个 rm_sim？

分情况。

### 可以：目标机器路径、用户、系统完全一样

目标机器满足：

```text
Ubuntu 22.04
ROS 2 Humble
用户名: shaun
路径: /home/shaun/static/Mtools/rm_sim
```

则可以用 `cp -a` 或 `tar` 完整复制，包括：

```text
envs/
third_party/
build/
install/
log/
```

但系统依赖仍然需要安装。

### 不可以：直接复制到任意路径

当前 `envs` 里有：

```text
622 个指向绝对路径的符号链接
74 个 install 文件包含 /home/shaun/static/Mtools
```

典型绝对链接：

```text
envs/nav_2026/install/cod_serial_ul26/lib/cod_serial_ul26/cod_serial
  -> /home/shaun/static/Mtools/rm_sim/envs/nav_2026/build/cod_serial_ul26/cod_serial
```

如果复制到：

```text
/home/robot/rm_sim
/opt/rm_sim
```

这些链接和 install 路径会失效。

另外 `envs/` 和 `third_party/` 被 `.gitignore` 忽略，所以：

```bash
git clone ...
```

只会得到仓库入口、配置、工具和文档，不会得到完整可运行环境。

## 2. 推荐方案：源码迁移 + 新机器重编译

这是最稳的方案。

### 第一步：在旧机器打包

```bash
cd /home/shaun/static/Mtools/rm_sim
scripts/make_migration_bundle.sh
```

输出：

```text
dist/rm_sim_repo_YYYYMMDD_HHMMSS.tar.gz
dist/rm_sim_sources_YYYYMMDD_HHMMSS.tar.gz
dist/MANIFEST_YYYYMMDD_HHMMSS.txt
```

两个包的分工：

```text
rm_sim_repo_*.tar.gz
  仓库入口、scripts、tools、docs、assets、pcd、media

rm_sim_sources_*.tar.gz
  envs/*/src
  envs/sim_tools/sim2026
  envs/sim_tools/pointlio_sim
  third_party 源码
  不包含 build/install/log
```

把两个包复制到新机器。

### 第二步：新机器解压

```bash
mkdir -p "$HOME/static/Mtools/rm_sim"
cd "$HOME/static/Mtools/rm_sim"

tar xzf /path/to/rm_sim_repo_YYYYMMDD_HHMMSS.tar.gz
tar xzf /path/to/rm_sim_sources_YYYYMMDD_HHMMSS.tar.gz
```

建议仍然使用：

```text
/home/<user>/static/Mtools/rm_sim
```

路径可以不同，但后面必须重新编译。

### 第三步：安装系统依赖

可以先执行一键脚本：

```bash
cd /home/robot/static/Mtools/rm_sim
scripts/install_deps.sh
```

默认会安装 ROS/Gazebo/Nav2/PCL、RealSense 和 Livox-SDK2。

如果不需要 RealSense：

```bash
scripts/install_deps.sh --no-realsense
```

如果已经手动安装过 Livox-SDK2：

```bash
scripts/install_deps.sh --no-livox-sdk
```

手动安装的 apt 列表如下：

```bash
sudo apt update

sudo apt install -y \
  ros-humble-navigation2 \
  ros-humble-nav2-bringup \
  ros-humble-gazebo-ros-pkgs \
  ros-humble-gazebo-plugins \
  ros-humble-pointcloud-to-laserscan \
  ros-humble-pcl-ros \
  ros-humble-pcl-conversions \
  ros-humble-tf2-ros \
  ros-humble-tf2-geometry-msgs \
  ros-humble-robot-state-publisher \
  ros-humble-joint-state-publisher \
  ros-humble-xacro \
  ros-humble-rviz2 \
  ros-humble-rqt-gui-py \
  ros-humble-topic-tools \
  python3-pyqt5 \
  python3-yaml \
  python3-colcon-common-extensions \
  libpcl-dev \
  libeigen3-dev \
  cmake \
  build-essential \
  git
```

如果需要 RealSense：

```bash
sudo apt install -y ros-humble-realsense2-camera
```

当前 `cod_bringup/singlenav_launch.py` 会 include 这个包。

### 第四步：安装 Livox-SDK2

```bash
cd /home/<user>/static/Mtools/rm_sim/third_party/Livox-SDK2
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc)"
sudo cmake --install build
sudo ldconfig
```

### 第五步：如果路径变了，替换绝对路径

假设旧路径：

```text
/home/shaun/static/Mtools/rm_sim
```

新路径：

```text
/home/robot/static/Mtools/rm_sim
```

执行：

```bash
cd /home/robot/static/Mtools/rm_sim
scripts/rewrite_paths.sh \
  /home/shaun/static/Mtools/rm_sim \
  /home/robot/static/Mtools/rm_sim
```

这个脚本会处理 Gazebo world、仿真参数、文档和桌面入口里的绝对路径。

### 第六步：重新编译全部环境

```bash
cd /home/robot/static/Mtools/rm_sim
scripts/build_all.sh
```

编译顺序：

```text
livox_mid360s
  -> fastlio
  -> pointlio
  -> sim_tools
  -> nav_2026
  -> rqt_ui
```

### 第七步：检查环境

```bash
scripts/check_env.sh
```

它会检查：

```text
ROS 2 Humble
Gazebo
Nav2
PyQt5 / PyYAML
workspace 内的包
/dev/ttyACM0
dialout 权限
USB 网卡 192.168.1.50
```

### 第八步：安装桌面启动器

```bash
scripts/install_desktop.sh
```

会重新生成：

```text
LIO-Tuner.desktop
~/Desktop/LIO-Tuner.desktop
~/.local/share/applications/LIO-Tuner.desktop
```

因为 `.desktop` 里的 `Exec=` 是绝对路径，所以换路径后必须重新生成。

### 第九步：验证

```bash
cd /home/robot/static/Mtools/rm_sim
source scripts/setup_split.sh

ros2 pkg prefix fast_lio
ros2 pkg prefix small_point_lio
ros2 pkg prefix livox_ros_driver2
ros2 pkg prefix nav_bringup
ros2 pkg prefix cod_serial_ul26

scripts/run_fastlio_2026.sh
```

另开终端发目标：

```bash
scripts/go_fastlio_2026.sh 4.6 -5.5 0
```

测试 LIO Tuner：

```bash
scripts/run_lio_tune_gui.sh
```

## 3. 快速方案：保持完全相同的绝对路径

如果新机器也是同一用户、同一路径，可以直接完整复制：

```bash
# 旧机器
cd /home/shaun/static/Mtools
tar czf rm_sim_full.tar.gz rm_sim

# 新机器，必须先创建同样的目录和用户
mkdir -p /home/shaun/static/Mtools
cd /home/shaun/static/Mtools
tar xzf /path/to/rm_sim_full.tar.gz
```

这条路线的前提：

```text
用户名必须还是 shaun
路径必须还是 /home/shaun/static/Mtools/rm_sim
Ubuntu / ROS 版本必须一致
```

否则不要复制 `build/` 和 `install/`，改用源码重编译方案。

## 4. 不建议复制的内容

换路径时不要复制：

```text
envs/*/build
envs/*/install
envs/*/log
third_party/Livox-SDK2/build
```

原因：

```text
CMake 缓存路径
可执行文件绝对链接
install setup 脚本里的绝对前缀
```

## 5. 迁移后仍然需要注意

### RealSense

当前 `cod_bringup/singlenav_launch.py` include 了：

```text
realsense2_camera/rs_launch.py
```

如果新机器没有安装：

```text
Package not found: realsense2_camera
```

需要安装，或者把这一段 include 注释掉。

### 串口

真机串口：

```text
/dev/ttyACM0
115200 8N1
```

权限：

```bash
sudo usermod -aG dialout "$USER"
```

重新登录后生效。

### 真实雷达网络

必须配置：

```text
主机: 192.168.1.50/24
雷达: 192.168.1.137
```

检查：

```bash
ip -br addr
ping -c 3 192.168.1.137
```

### MID-360S 型号

必须使用：

```text
MID360s_config.json
livox_ros_driver2 1.2.8
Livox-SDK2 1.5.2
```

不要使用旧版 1.0.0 或 Livox Viewer 2.3.0。

### Nav2 包名问题

`nav_bringup/launch/bringup.launch.py` 仍然写的是旧包名：

```text
cod_serial
```

当前串口包名是：

```text
cod_serial_ul26
```

如果走这个 launch，需要改成 `cod_serial_ul26`。

## 6. 迁移检查清单

```text
[ ] 新机器 Ubuntu 22.04 + ROS 2 Humble
[ ] 系统依赖安装完成
[ ] Livox-SDK2 安装完成
[ ] envs/third_party 源码已复制
[ ] 绝对路径已替换
[ ] scripts/build_all.sh 成功
[ ] scripts/check_env.sh 无 FAIL
[ ] FAST-LIO 仿真能启动
[ ] Point-LIO 仿真能启动
[ ] 目标点能发送
[ ] LIO Tuner 能双击启动
[ ] 真机雷达 IP 和串口权限正确
```
