# 真实 MID-360S 雷达：连接、点云和 RViz

目标：接上真实 Livox MID-360S，看到 PointCloud2 点云，并正确处理 TF。

## 1. 硬件

需要：

```text
Livox MID-360S
雷达电源
网线
USB 转以太网网卡
```

连接：

```text
雷达网口 -> 网线 -> USB 网卡 -> 电脑
雷达电源单独供电
```

## 2. 网络

当前约定：

```text
电脑: 192.168.1.50/24
雷达: 192.168.1.137
```

检查网卡：

```bash
ip -br addr
```

必须看到类似：

```text
enxfce...  192.168.1.50/24
```

如果看到：

```text
196.168.1.50/24
```

是地址写错了。

如果完全没有 `enx...`：

```text
USB 网卡没识别
检查 USB 网卡、USB Hub、供电
```

临时补地址：

```bash
sudo ip addr add 192.168.1.50/24 dev <你的enx网卡>
sudo ip link set <你的enx网卡> up
```

检查雷达：

```bash
ping -c 3 192.168.1.137
```

必须通。

## 3. 启动驱动、TF 和 RViz

```bash
/home/shaun/static/Mtools/rm_sim/scripts/run_lidar.sh
```

它启动：

```text
livox_ros_driver2（xfer_format=0，PointCloud2）
world -> livox_frame 静态 TF
rviz2（livox_pointcloud.rviz）
```

## 4. 检查点云

另开终端：

```bash
source /opt/ros/humble/setup.bash
source /home/shaun/static/Mtools/rm_sim/scripts/setup_split.sh

ros2 topic type /livox/lidar
# sensor_msgs/msg/PointCloud2

ros2 topic hz /livox/lidar
# 约 10 Hz

ros2 topic hz /livox/imu
# 有数据
```

## 5. 检查 TF

```bash
ros2 run tf2_ros tf2_echo world livox_frame
```

RViz 里：

```text
Fixed Frame: world
PointCloud2 Topic: /livox/lidar
Style: Flat Squares
Size (m): 0.02
Decay Time: 0.5
```

如果报：

```text
Frame [livox_frame] does not exist
```

说明 TF 没发布，检查 `run_lidar.sh` 是否正常启动。

## 6. 配置文件

驱动 IP 配置：

```text
envs/livox_mid360s/install/livox_ros_driver2/share/livox_ros_driver2/config/MID360s_config.json
```

关键：

```json
"host_ip": "192.168.1.50"
"ip": "192.168.1.137"
```

RViz 配置：

```text
envs/livox_mid360s/livox_pointcloud.rviz
```

## 7. 点云太稀/太密

在 RViz 的 `PointCloud2` 中调：

```text
Decay Time:
  0     只显示当前帧，最稀
  0.5   推荐
  1~2   更密，但可能拖影

Size (m):
  0.01  细
  0.02  推荐
  0.05  更明显
```

真正降采样不是 RViz，而是 LIO：

```text
FAST-LIO:
  point_filter_num
  filter_size_surf
  filter_size_map

Point-LIO:
  point_filter_num
  space_downsample_leaf_size
```

## 8. 停止

运行 `run_lidar.sh` 的终端按 `Ctrl+C`。

## 9. 注意

`run_lidar.sh` 是 **PointCloud2 + RViz 看点云**。

如果要跑 FAST-LIO 真实建图，驱动要换成：

```bash
ros2 launch livox_ros_driver2 msg_MID360s_launch.py
```

因为 FAST-LIO 配置使用 Livox `CustomMsg`。详见：

```text
docs/TUTORIAL_MAPPING.md
```
