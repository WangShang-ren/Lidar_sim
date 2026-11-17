# 教学文档总目录

建议按顺序阅读：

| 顺序 | 文档 | 内容 |
|---|---|---|
| 0 | [README](../README.md) | 项目结构、版本、依赖、构建和统一入口 |
| 1 | [虚拟仿真：FAST-LIO](TUTORIAL_SIM_FASTLIO.md) | 不接实物雷达，跑 2026 Gazebo + FAST-LIO + Nav2 |
| 2 | [虚拟仿真：Point-LIO](TUTORIAL_SIM_POINTLIO.md) | 不接实物雷达，跑 2026 Gazebo + Point-LIO + Nav2 |
| 3 | [真实 MID-360S 雷达](TUTORIAL_LIDAR.md) | 供电、网络、驱动、PointCloud2、RViz |
| 4 | [真实雷达建图](TUTORIAL_MAPPING.md) | 真实雷达 + FAST-LIO 建图、保存 PCD、转地图 |
| 5 | [LIO 调参](TUTORIAL_LIO_TUNE.md) | CLI、PyQt5、rqt 插件、重启和回滚 |
| 6 | [TF 和 RViz](TF_AND_RVIZ.md) | `livox_frame`、Fixed Frame、PointCloud2 显示 |
| 7 | [常见问题](TROUBLESHOOTING.md) | `bind failed`、无点云、TF 警告、Gazebo GUI 崩溃 |
| 8 | [代码阅读](CODE_GUIDE.md) | 从 launch 到 C++ 的阅读路线 |
| 9 | [工作区分层](WORKSPACES.md) | `envs/` 每个工作区的作用 |
| 10 | [SLAM 问答](SLAM_QA.md) | SLAM、论文、Odin、代码理解准备 |
| 11 | [串口协议与 COD 代码](TUTORIAL_SERIAL.md) | 15 字节速度帧、校验和、`cod_serial` 代码位置 |
| 12 | [迁移到另一台机器](TUTORIAL_MIGRATION.md) | 源码打包、依赖、重编译、路径替换、桌面启动器 |

## 最短路径

只想看仿真：

```bash
cd /home/shaun/static/Mtools/rm_sim
source scripts/setup_split.sh
scripts/run_fastlio_2026.sh
```

只想看真实雷达点云：

```bash
cd /home/shaun/static/Mtools/rm_sim
scripts/run_lidar.sh
```

真实雷达建图：

```bash
# 终端 1
source /home/shaun/static/Mtools/rm_sim/scripts/setup_split.sh
ros2 launch livox_ros_driver2 msg_MID360s_launch.py

# 终端 2
source /home/shaun/static/Mtools/rm_sim/scripts/setup_split.sh
ros2 launch fast_lio mapping.launch.py rviz:=true use_sim_time:=false
```

## 运行前统一检查

```bash
cd /home/shaun/static/Mtools/rm_sim
source /opt/ros/humble/setup.bash
source scripts/setup_split.sh
```

确认包和节点都在：

```bash
ros2 pkg prefix fast_lio
ros2 pkg prefix small_point_lio
ros2 pkg prefix livox_ros_driver2
ros2 pkg prefix nav_bringup
```

## 文档目录

```text
docs/
├── TUTORIAL_INDEX.md
├── TUTORIAL_SIM_FASTLIO.md
├── TUTORIAL_SIM_POINTLIO.md
├── TUTORIAL_LIDAR.md
├── TUTORIAL_MAPPING.md
├── TUTORIAL_LIO_TUNE.md
├── TUTORIAL_SERIAL.md
├── TUTORIAL_MIGRATION.md
├── TROUBLESHOOTING.md
├── WORKSPACES.md
├── CODE_GUIDE.md
├── TF_AND_RVIZ.md
├── SLAM_QA.md
├── CHANGES.md
└── THIRD_PARTY.md
```
