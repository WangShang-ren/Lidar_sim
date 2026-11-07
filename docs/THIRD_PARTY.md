# 第三方来源与许可

本仓库只包含整理后的仿真入口、配置、工具和效果素材。以下内容来自第三方或依赖第三方运行，版权归原作者所有。

## 上游仓库

| 项目 | 用途 | 地址 |
|---|---|---|
| COD_NAV | COD 导航、FAST-LIO、Gazebo 仿真基础 | https://github.com/qza36/COD_NAV |
| COD_RM2026_Navigation | 2026 导航框架、Point-LIO、Nav2 配置 | https://gitee.com/codnavgation/cod_-rm2026_-navigation |
| livox_ros_driver2 | Livox ROS 2 驱动 | https://github.com/Livox-SDK/livox_ros_driver2 |
| Livox-SDK2 | Livox 底层 SDK | https://github.com/Livox-SDK/Livox-SDK2 |
| Navigation2 | Nav2 导航框架 | https://github.com/ros-navigation/navigation2 |
| Gazebo Classic | 仿真环境 | https://classic.gazebosim.org/ |
| small_gicp | 点云配准库 | https://github.com/koide3/small_gicp |

## 场地和地图

- 2026 3v3 地图：整理自 COD_RM2026_Navigation 的 `rmul2026.pgm/yaml`
- 2026 3v3 场地 STL/world：来自社区开源 `26rmu_gazebo_simulator` 的 RMUL 2026 场地模型  
  https://github.com/jiedong01/26rmu_gazebo_simulator
- 场地模型仅用于仿真调试，若与官方规则/现场场地有差异，以官方规则和现场为准

## PCD

`pcd/RM2026.pcd` 来自参考工程 `T-DT_Radar/config/RM2026.pcd`，不是本仓库仿真过程生成的新 PCD。详见 `pcd/README.md`。

## 说明

如果要将本仓库公开，请根据上游项目的许可证保留相应版权和许可声明。  
本仓库没有重新授权第三方代码、地图、场地模型或 PCD。
