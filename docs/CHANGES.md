# 主要修改记录

本仓库只整理仿真入口、配置、工具和素材；完整上游代码不在此仓库。

## COD_NAV / FAST-LIO 仿真入口

- 新增 `sim2026/` 目录：
  - 使用 2026 3v3 地图 `rmul2026.pgm/yaml`
  - 使用社区 RMUL 2026 场地 STL/world
  - Gazebo 使用 `gzserver` 无界面运行，RViz 显示
  - 机器人出生点放在场地左侧自由区
  - 增加 `map -> odom` 静态变换，使地图坐标和 Gazebo 世界对齐
- 修复：
  - `small_gicp` 头文件缺失
  - `small_gicp_relocalization` 使用 C++17
  - 移除 `-Werror`，避免第三方代码警告导致构建失败
  - `mid360.xacro` 增加 `<always_on>true</always_on>`
  - Nav2 参数增加 `consider_footprint: false`，避免启动崩溃
  - `sim_lio_only` 的 `map -> odom` 静态 TF 增加 `use_sim_time`

## COD_RM2026 / Point-LIO 仿真入口

- 新增 `cod26_sim/`：
  - 使用 `small_point_lio` / Point-LIO
  - 增加 Gazebo 2026 world
  - 增加 `livox_timebase_fix.py`，修正 Gazebo Livox 插件 `timebase=0` 的问题
  - 增加 `cpp_lidar_filter`、`fake_vel_transform`、topic relay 等仿真适配
- 调整 Point-LIO 参数：
  - `check_satu: false`
  - `acc_norm: 9.81`
  - 适配 Gazebo IMU 输出单位

## MID-360S 真实雷达

- 雷达型号：Livox MID-360S
- 使用较新的 `livox_ros_driver2 1.2.8`
- 使用 `MID360s_config.json`
- 示例网络配置：
  - 主机：`192.168.1.50/24`
  - 雷达：`192.168.1.137`
- 旧版 `livox_ros_driver2 1.0.0` / Livox Viewer 2.3.0 不支持 MID-360S

## 已知限制

- Gazebo Classic `gzclient` 在本机存在 Ogre 崩溃，因此仿真只开 `gzserver`，用 RViz 看效果。
- 2026 COD 地图和社区场地 STL 存在局部偏差，右侧和中央部分点位可能卡住。
- 独立启动真实雷达时，RViz 需要额外发布 `map -> livox_frame` 或 `base_link -> livox_frame` 静态 TF。
