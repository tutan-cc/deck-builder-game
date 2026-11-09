class_name Stats
extends Resource

## 生命 / 格挡 / 状态。
## 状态用字符串键 + 层数，简单但够用：力量（+伤害）、易伤（受伤 ×1.5）、虚弱（伤害 ×0.75）。

signal stats_changed

const STRENGTH := "strength"
const VULNERABLE := "vulnerable"
const WEAK := "weak"

const STATUS_LABELS := {
	STRENGTH: "力",
	VULNERABLE: "易",
	WEAK: "弱",
}

@export var max_health := 1: set = set_max_health
@export var art: Texture2D

var health: int: set = set_health
var block: int: set = set_block
var statuses := {}


func _init() -> void:
	health = max_health


func set_health(value: int) -> void:
	health = clampi(value, 0, max_health)
	stats_changed.emit()


func set_max_health(value: int) -> void:
	var diff := value - max_health
	max_health = value
	if diff > 0:
		health += diff
	elif health > max_health:
		health = max_health
	stats_changed.emit()


func set_block(value: int) -> void:
	block = clampi(value, 0, 999)
	stats_changed.emit()


# ---------- 状态 ----------

func add_status(status: String, stacks: int) -> void:
	var next: int = int(statuses.get(status, 0)) + stacks
	if next <= 0:
		statuses.erase(status)
	else:
		statuses[status] = next
	stats_changed.emit()


func get_status(status: String) -> int:
	return int(statuses.get(status, 0))


func has_status(status: String) -> bool:
	return get_status(status) > 0


## 回合结束扣一层（易伤/虚弱这类按回合递减）
func tick_statuses() -> void:
	for key in statuses.keys():
		var remaining: int = int(statuses[key]) - 1
		if remaining <= 0:
			statuses.erase(key)
		else:
			statuses[key] = remaining
	stats_changed.emit()


func clear_statuses() -> void:
	statuses.clear()
	stats_changed.emit()


## 状态在界面上怎么显示："力2 易1"
func status_text() -> String:
	var parts: Array = []
	for key in statuses.keys():
		parts.append("%s%d" % [STATUS_LABELS.get(key, key), int(statuses[key])])
	return " ".join(parts)


# ---------- 结算 ----------

func take_damage(damage: int) -> void:
	if damage <= 0:
		return
	# 格挡先顶，顶不完的才进血
	var absorbed := mini(block, damage)
	block -= absorbed
	health = health - (damage - absorbed)
	stats_changed.emit()


func heal(value: int) -> void:
	health = health + value


func add_block(value: int) -> void:
	block = block + value


func clear_block() -> void:
	block = 0
