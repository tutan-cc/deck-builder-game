class_name Relic
extends Resource

## P20/P37：遗物。之前只有"加属性"，现在有两种：
## 1. PASSIVE：开局改数值（能量上限、最大生命）
## 2. 触发式：每回合开始给格挡/能量、受伤时减伤
##
## 加一个新遗物 = new 一个 Resource，不用改 Battle。

enum Trigger { PASSIVE, TURN_START_BLOCK, TURN_START_ENERGY, DAMAGE_REDUCTION }

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var trigger: Trigger = Trigger.PASSIVE
@export var amount := 0
@export var bonus_energy := 0
@export var bonus_max_health := 0
@export var icon: Texture2D


## 开局（每次战斗创建玩家数值时）调用
func apply_to(stats: CharacterStats) -> void:
	stats.max_energy += bonus_energy
	stats.max_health += bonus_max_health
	stats.health += bonus_max_health
	stats.energy = stats.max_energy


## 玩家回合开始时调用
func on_turn_start(player: Node) -> void:
	match trigger:
		Trigger.TURN_START_BLOCK:
			if player.has_method("add_block"):
				player.add_block(amount)
		Trigger.TURN_START_ENERGY:
			player.stats.energy = player.stats.energy + amount
		_:
			pass
