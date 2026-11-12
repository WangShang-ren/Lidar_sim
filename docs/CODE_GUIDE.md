# 项目代码阅读指南

## 先说明：这个 GitHub 仓库不是完整代码库

`rm_sim` 是“仿真入口 + 工具 + 素材”的整理包，主要放：

- Python launch 文件
- Shell 启动脚本
- YAML 参数
- RViz 配置
- URDF / world / STL
- 自研调参工具

真正的算法代码在三个外部工作区：

```text
/home/shaun/static/Mtools/rm_sim/envs/fastlio
/home/shaun/static/Mtools/rm_sim/envs/pointlio
/home/shaun/static/Mtools/rm_sim/envs/livox_mid360s
```

所以看起来“只有 Python 和 sh”，是因为仓库只保存了集成层；C++ 的 LIO、驱动、Nav2 插件在上游工作区里。

## 规模参考

```text
cod_ws   : 约 199 个 C/C++ 头文件和源文件
cod26_ws : 约 57 个
livox_ws : 约 70 个
```

## 1. 先读集成层

从仓库根目录按顺序读：

1. `README.md`
2. `docs/TF_AND_RVIZ.md`
3. `docs/CHANGES.md`
4. `docs/SLAM_QA.md`

这些文档解释：

```text
系统目标
TF 关系
启动顺序
为什么要改这些参数
```

## 2. 再读 Shell 启动脚本

这些脚本是“总控”，负责按顺序启动节点：

```text
code/sim2026/run_sim_2026.sh
code/cod26_sim/run_cod26_sim.sh
code/livox_ws/run_mid360s_rviz.sh
```

重点看：

```text
source 了哪些工作区
启动了哪些 launch
等待了哪些 topic / node
发布了哪些 static TF
最后如何激活 Nav2
```

## 3. 读 launch 文件

launch 文件不是普通配置，它决定节点和话题：

```text
code/sim2026/launch/gazebo_rmul2026_cod.launch.py
code/sim2026/launch/sim_lio_only_2026.launch.py
code/cod26_sim/launch/gazebo_rmul2026.launch.py
code/livox_ws/livox_rviz.launch.py
```

重点看：

```text
Node(package=..., executable=...)
parameters=...
remappings=...
arguments=...
```

例如：

- `livox_rviz.launch.py` 里同时启动 `world -> livox_frame`、驱动和 RViz
- `gazebo_rmul2026_cod.launch.py` 里启动 `gzserver` 和 `spawn_entity.py`

## 4. 读配置

```text
code/sim2026/params/sim_nav2_params_2026.yaml
code/cod26_sim/config/mid360_sim.yaml
code/cod26_sim/config/sim_singlenav2_params.yaml
code/livox_ws/MID360s_config.example.json
```

重点：

```text
FAST-LIO:
  point_filter_num
  filter_size_surf
  filter_size_map

Point-LIO:
  point_filter_num
  space_downsample_leaf_size
  extrinsic_T / extrinsic_R

Nav2:
  robot_base_frame
  global_frame
  observation_sources
  map_server.yaml_filename
```

## 5. 读 C++ 核心代码

### FAST-LIO

```text
/home/shaun/static/Mtools/rm_sim/envs/fastlio/src/fast_lio/src/laserMapping.cpp
/home/shaun/static/Mtools/rm_sim/envs/fastlio/src/fast_lio/src/IMU_Processing.hpp
/home/shaun/static/Mtools/rm_sim/envs/fastlio/src/fast_lio/src/preprocess.cpp
```

入口：

```text
laserMapping.cpp
  -> main()
  -> 订阅 lidar/imu
  -> 前端匹配
  -> 发布 odom / 点云 / TF
```

### Point-LIO / small_point_lio

```text
/home/shaun/static/Mtools/rm_sim/envs/pointlio/src/small_point_lio/src/small_point_lio_node.cpp
/home/shaun/static/Mtools/rm_sim/envs/pointlio/src/small_point_lio/src/small_point_lio/small_point_lio.cpp
/home/shaun/static/Mtools/rm_sim/envs/pointlio/src/small_point_lio/src/small_point_lio/estimator.cpp
/home/shaun/static/Mtools/rm_sim/envs/pointlio/src/small_point_lio/src/small_point_lio/parameters.cpp
/home/shaun/static/Mtools/rm_sim/envs/pointlio/src/small_point_lio/src/lidar_adapter/
```

入口：

```text
small_point_lio_node.cpp
  -> 订阅 /livox/lidar 和 /livox/imu
  -> 调用 SmallPointLio::handle_once()
  -> 发布 /Odometry 和 /cloud_registered
```

### Livox 驱动

```text
/home/shaun/static/Mtools/rm_sim/envs/livox_mid360s/src/livox_ros_driver2/src/livox_ros_driver2.cpp
/home/shaun/static/Mtools/rm_sim/envs/livox_mid360s/src/livox_ros_driver2/src/lds_lidar.cpp
/home/shaun/static/Mtools/rm_sim/envs/livox_mid360s/src/livox_ros_driver2/src/lddc.cpp
/home/shaun/static/Mtools/rm_sim/envs/livox_mid360s/src/livox_ros_driver2/src/comm/pub_handler.cpp
```

重点：

```text
xfer_format = 0 -> PointCloud2
xfer_format = 1 -> CustomMsg
```

### Nav2 插件和底盘适配

```text
/home/shaun/static/Mtools/rm_sim/envs/nav_2026/src/cpp_lidar_filter
/home/shaun/static/Mtools/rm_sim/envs/nav_2026/src/fake_vel_transform
/home/shaun/static/Mtools/rm_sim/envs/nav_2026/src/goal_approach_controller
/home/shaun/static/Mtools/rm_sim/envs/nav_2026/src/pb_omni_pid_pursuit_controller
/home/shaun/static/Mtools/rm_sim/envs/nav_2026/src/pb_nav2_plugins
```

## 6. 读代码时配合 ROS 图

不要只看文件，配合运行时观察最快：

```bash
ros2 node list
ros2 topic list
ros2 node info /small_point_lio
ros2 topic info /livox/lidar -v
ros2 run rqt_graph rqt_graph
ros2 run tf2_tools view_frames
ros2 run rqt_tf_tree rqt_tf_tree
```

推荐顺序：

```text
先看 node 列表
再看 topic 连接
再看 TF 树
最后回到 C++ 找发布者/订阅者
```

## 7. 最推荐的阅读路线

1. `README.md`
2. `run_sim_2026.sh` / `run_cod26_sim.sh`
3. `launch/*.py`
4. `params/*.yaml`
5. `small_point_lio_node.cpp` 或 `laserMapping.cpp`
6. `estimator.cpp` / `IMU_Processing.hpp`
7. `livox_ros_driver2.cpp` / `pub_handler.cpp`
8. Nav2 插件

## 8. 一句话

```text
你看到的 Python/sh 是“集成层”；
真正让系统工作的 C++ 在 cod_ws / cod26_ws / livox_ws 里。
把 launch、topic、TF、C++ 入口按链路串起来，就能看懂项目。
```
