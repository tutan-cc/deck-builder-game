# deck builder game — 重建工程

> **分集说明（P1–P10，每集做了什么、踩了什么坑）见 [`docs/分集说明.md`](docs/分集说明.md)。**
> 这份笔记只记前三集的落地细节，保留作背景。

对照 B 站《Godot〈杀戮尖塔〉卡牌游戏全集》P1–P3（英文原作 Godot Gamela / `guladam/deck_builder_tutorial`）重建。
素材来自原作仓库的 `season-1-starter-project` 分支（Kenney Tiny Dungeon 切片 + 音效 + 像素字体）。

## 三集各做了什么

| 集 | 视频 | 这里的落点 |
|---|---|---|
| P1 | 项目创建 / 场景搭建 / 资源导入 | `project.godot`（256×144 视口、1280×720 窗口、viewport 拉伸、最近邻采样、Mobile 渲染器）+ `scenes/battle/battle.tscn` 的 `background.png` |
| P2 | 卡牌拖拽机制：从状态机到叠放交互 | `scenes/card_ui/`：CardUI（Control）+ 状态机 + 四个状态；`scenes/ui/hand.tscn`（HBoxContainer 发牌） |
| P3 | 拖拽中的悬停判定与释放逻辑 | 悬停放大（base 态 1.12×）、松手落点判定（出牌区 → 打出去消失；区外 → 回原位） |

## 状态机

```
base ──左键按下──> clicked ──移动超过 4px──> dragging ──松开──> released
 ↑                                                                  │
 └──────────────── 落点在区外：0.15s 后回 base ─────────────────────┘
                   落点在出牌区：打出去，卡牌 queue_free
```

- `card_state_machine.gd`：只负责「谁当前、切过去、把输入转给当前状态」；迟到的切换请求会被丢掉（`from != current_state` 直接 return）。
- 每个状态是 `CardStateMachine` 的子节点，`state` 用枚举标号（0..3）。
- `base` 不跑 `_process`，所以挂多少张卡都不掉帧。

## 两个"踩过就记住"的点

1. **拖动必须脱离容器。** 卡留在 `HBoxContainer` 里的话，容器每帧都会把位置改回布局结果，拽不动。`dragging` 进入时 `reparent(ui_layer)`，`released` 时按 `original_index` 搬回去。
2. **Control 挂在 Node2D 下，锚点会算成 0。** 第一次跑出来手牌整块在 (-148,-84)，因为 Node2D 没有矩形、锚点按 0×0 解析。UI 统一放进 `CanvasLayer`（`UILayer`）后就对了。

## 怎么跑

```powershell
& "D:\deepseek工作区\Godot\Godot_v4.7.2-stable_win64_console.exe" --path "D:\deepseek工作区\deck-builder-game"
```

`F5` 直接进战斗场景，五张卡可以真的拖。

## 自检

```powershell
& "...\Godot_v4.7.2-stable_win64_console.exe" --path "D:\deepseek工作区\deck-builder-game" res://tools/feat_test.tscn
```

不看动画也能验：走完 base → clicked → dragging → released，断言
`drop_in_zone=true` / `drop_out_zone=false` / 回原位后 `hand=5` / 打出后 `hand=4`，
并把四个瞬间存成 `shots/*.png`。`CardUI.debug_mouse` 就是为这个留的测试接缝。

## 和视频的差异（都记在这里，别当成 bug）

- 视频用 **Godot 4.1/4.3**，这里是 **4.7.2**；工程按 4.7 的 `config/features` 写。
- 视频里出牌区是后面才做的 `Area2D`；这一集用 **Control + 矩形判定**，够用且不依赖物理查询。
- 卡面还是**调试配色**（每种状态一个颜色 + 状态名），真卡面（费用/插图/描述）是后面集数的事。
