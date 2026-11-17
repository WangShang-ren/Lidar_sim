# 真实 MID-360S 建图：FAST-LIO 建图并保存 PCD

目标：用真实 MID-360S 走一圈，在 RViz 里看到点云地图，保存 PCD，再转成 Nav2 栅格地图。

## 1. 前置

网络正常：

```bash
ip -br addr
# 192.168.1.50/24

ping -c 3 192.168.1.137
```

如果 `run_lidar.sh` 正在运行，先停止。  
建图使用 Livox `CustomMsg`，不要再同时启动 PointCloud2 版本的驱动。

## 2. 终端 1：启动真实雷达 CustomMsg 驱动

```bash
source /opt/ros/humble/setup.bash
source /home/shaun/static/Mtools/rm_sim/scripts/setup_split.sh

ros2 launch livox_ros_driver2 msg_MID360s_launch.py
```

检查：

```bash
ros2 topic type /livox/lidar
# livox_ros_driver2/msg/CustomMsg

ros2 topic hz /livox/lidar
ros2 topic hz /livox/imu
```

## 3. 终端 2：启动 FAST-LIO

```bash
source /opt/ros/humble/setup.bash
source /home/shaun/static/Mtools/rm_sim/scripts/setup_split.sh

ros2 launch fast_lio mapping.launch.py \
  rviz:=true \
  use_sim_time:=false \
  config_file:=mid360.yaml
```

会启动：

```text
fastlio_mapping
rviz2（fastlio.rviz）
```

RViz 中重点看：

```text
/cloud_registered
/Odometry
/Laser_map
```

## 4. 开始建图

拿着雷达：

```text
慢慢走
不要快速甩动
绕场地一圈
尽量回到起点附近
```

在 RViz 中观察 `/cloud_registered` 逐渐累积。

检查：

```bash
ros2 topic hz /Odometry
ros2 topic hz /cloud_registered
```

## 5. 保存 PCD

配置文件：

```text
envs/fastlio/install/fast_lio/share/fast_lio/config/mid360.yaml
```

已有：

```yaml
pcd_save:
  pcd_save_en: true
  interval: -1
```

建议把 `map_file_path` 改成绝对路径：

```yaml
map_file_path: "/home/shaun/static/Mtools/rm_sim/pcd/fastlio_scan.pcd"
```

然后重新启动 FAST-LIO，完成建图后正常 `Ctrl+C` 退出，检查：

```bash
ls -lh /home/shaun/static/Mtools/rm_sim/pcd/fastlio_scan.pcd
```

如果没有生成，检查：

```bash
grep -nE 'pcd_save_en|map_file_path' envs/fastlio/install/fast_lio/share/fast_lio/config/mid360.yaml
```

## 6. Point-LIO 建图（可选）

Point-LIO 需要：

```text
驱动发布 PointCloud2
静态 TF: base_link -> livox_frame
small_point_lio 配置 save_pcd: true
```

调用保存：

```bash
ros2 service call /map_save std_srvs/srv/Trigger
```

PCD 通常在：

```text
envs/pointlio/src/small_point_lio/pcd/
```

## 7. PCD 转栅格地图

配置：

```text
envs/sim_tools/src/pcd2pgm/config/pcd2pgm.yaml
```

设置：

```yaml
pcd_file: "/home/shaun/static/Mtools/rm_sim/pcd/fastlio_scan.pcd"
```

启动：

```bash
source /home/shaun/static/Mtools/rm_sim/scripts/setup_split.sh
ros2 launch pcd2pgm pcd2pgm_launch.py
```

或者用 Nav2 保存栅格图：

```bash
ros2 run nav2_map_server map_saver_cli -f field_map
```

得到：

```text
field_map.pgm
field_map.yaml
```

## 8. 建图展示的最短流程

```text
1. 确认 192.168.1.50 和 192.168.1.137
2. 启动 msg_MID360s_launch.py
3. 启动 fast_lio mapping.launch.py
4. RViz 看 /cloud_registered
5. 拿雷达走一圈
6. Ctrl+C
7. 检查 PCD
8. pcd2pgm / map_saver_cli
```
