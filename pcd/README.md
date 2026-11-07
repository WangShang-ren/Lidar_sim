# PCD 文件说明

当前目录包含：

```text
RM2026.pcd
```

来源：

```text
T-DT_Radar/config/RM2026.pcd
```

它是 2026 地图点云参考文件，**不是**本仓库仿真过程中新建的 PCD。  
如果要上传自己的建图结果，建议直接替换这个文件，并在 README 中写明采集设备、场地和建图算法。

## FAST-LIO 保存 PCD

配置中开启：

```yaml
pcd_save:
  pcd_save_en: true
  interval: -1
```

并设置：

```yaml
map_file_path: "./your_map.pcd"
```

运行 FAST-LIO 后保存。

## Point-LIO / small_point_lio 保存 PCD

配置中开启：

```yaml
save_pcd: true
```

运行建图后调用：

```bash
ros2 service call /map_save std_srvs/srv/Trigger
```

生成的 PCD 在 `small_point_lio` 的 `pcd/scan.pcd`，具体路径以实际 package 为准。
