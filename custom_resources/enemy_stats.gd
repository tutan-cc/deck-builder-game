class_name EnemyStats
extends Stats

## 敌人用的数值：多一个"下回合要打多少"，也就是玩家看到的意图。

@export var display_name := "Enemy"
@export var attack_damage := 6
## P14：这个敌人会哪些动作，权重和条件都写在动作里
@export var actions: Array[EnemyAction] = []
## 出手时播的攻击帧条（可选）。留空就还是只有扑击位移
@export var attack_art: Texture2D


func roll_intent() -> int:
	# 这一集先固定伤害；随机意图是后面的集数
	return attack_damage
