
## 8. 中途增加目标或方向

### 方式 A：直接改当前目标

在仿真运行中再发一个新的目标，Nav2 会抢占当前目标：

```bash
/home/shaun/static/Mtools/rm_sim/scripts/go_fastlio_2026.sh 2.0 -5.0 45
```

第三个参数是 **yaw 角度**，单位是度：

```text
0     朝向 +X
90    朝向 +Y
180   朝向 -X
-90   朝向 -Y
```

所以：

```bash
# 先往左下方
scripts/go_fastlio_2026.sh 0.0 -5.5 0

# 中途改成另一方向
scripts/go_fastlio_2026.sh 4.6 -5.5 90
```

后一个目标会取消前一个目标。

### 方式 B：先到中间点，再到终点

如果不想取消第一个点，而是按顺序经过多个点，用 `NavigateThroughPoses`：

```bash
source /home/shaun/static/Mtools/rm_sim/scripts/setup_split.sh

ros2 action send_goal /navigate_through_poses \
  nav2_msgs/action/NavigateThroughPoses \
  "{poses: [
    {header: {frame_id: map}, pose: {position: {x: 0.0, y: -2.6, z: 0.0}, orientation: {x: 0.0, y: 0.0, z: 0.0, w: 1.0}}},
    {header: {frame_id: map}, pose: {position: {x: 4.6, y: -5.5, z: 0.0}, orientation: {x: 0.0, y: 0.0, z: 0.7071, w: 0.7071}}}
  ]}" \
  --feedback
```

上面的意思是：

```text
先到 (0.0, -2.6)，朝向 0°
再到 (4.6, -5.5)，朝向 90°
```

### 方式 C：在 RViz 里手动设置方向

RViz 工具栏选择：

```text
2D Goal Pose
```

在地图上点击目标位置，然后拖动箭头：

```text
箭头方向 = 目标朝向
```

松开鼠标后，RViz 会发布新的 `goal_pose`。

> 注意：新目标同样会抢占当前目标。  
> 要按顺序走多个点，用方式 B 的 `NavigateThroughPoses`。

### 验证

```bash
ros2 action list | grep navigate
ros2 topic echo /plan --once
```

如果只想到点后转一个方向，不需要多个点，直接用：

```bash
scripts/go_fastlio_2026.sh 4.6 -5.5 90
```
