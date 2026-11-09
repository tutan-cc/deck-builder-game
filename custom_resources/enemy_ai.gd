class_name EnemyAI
extends Resource

## P14：权重随机的动作选择器。
## 每个动作带 weight 和 min_turn，所以"第一回合只会打人、第三回合才开始防御"
## 这种条件行为不用写 if，直接配数据就行。

@export var actions: Array[EnemyAction] = []

var turn := 0


func reset() -> void:
	turn = 0


## 按权重抽一个动作；不满足 min_turn 的直接不进池子
func pick() -> EnemyAction:
	turn += 1
	var pool: Array[EnemyAction] = []
	var total := 0.0
	for action in actions:
		if action and action.min_turn <= turn and action.weight > 0.0:
			pool.append(action)
			total += action.weight
	if pool.is_empty():
		return null

	var roll := randf() * total
	for action in pool:
		roll -= action.weight
		if roll <= 0.0:
			return action
	return pool[pool.size() - 1]
