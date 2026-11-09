extends Node

## 状态系统自检：力量 / 易伤 / 虚弱 对伤害的影响，以及回合递减。
## 直接调 DamageEffect，绕开手牌与能量的干扰。

func _ready() -> void:
	RunState.start_run(Character.warrior())
	RunState.current_room = -1
	var battle: Battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await get_tree().create_timer(0.9).timeout

	var enemy: Node = get_tree().get_nodes_in_group("enemies")[0]
	enemy.stats.max_health = 999
	enemy.stats.health = 999

	var effect := DamageEffect.new()
	effect.amount = 6

	# ① 基础：6
	effect.execute([enemy], battle.player.stats)
	print("T base: 999 -> %d (期望 6)" % (999 - enemy.stats.health))

	# ② 玩家力量 +2 → 8
	battle.player.stats.add_status(Stats.STRENGTH, 2)
	var before: int = enemy.stats.health
	effect.execute([enemy], battle.player.stats)
	print("T strength: %d -> %d（期望 -8）" % [before, enemy.stats.health])

	# ③ 敌人易伤 → 12
	enemy.add_status(Stats.VULNERABLE, 2)
	before = int(enemy.stats.health)
	effect.execute([enemy], battle.player.stats)
	print("T vulnerable: %d -> %d (expect -12) vuln=%d" % [before, enemy.stats.health, enemy.stats.get_status(Stats.VULNERABLE)])

	# ④ 玩家虚弱 → (6+2)*0.75*1.5 = 9
	battle.player.stats.add_status(Stats.WEAK, 1)
	before = int(enemy.stats.health)
	effect.execute([enemy], battle.player.stats)
	print("T weak: %d -> %d（期望 -9）" % [before, enemy.stats.health])

	# ⑤ 回合递减
	battle.player.stats.tick_statuses()
	enemy.stats.tick_statuses()
	print("T tick: player=%s enemy=%s" % [
		battle.player.stats.status_text(), enemy.stats.status_text()])

	# ⑥ Bash 打上去会挂易伤
	var bash := CardLibrary.bash()
	enemy.stats.clear_statuses()
	bash.apply([enemy], battle.player.stats)
	print("T bash: vuln=%d strength_ok=%s" % [enemy.stats.get_status(Stats.VULNERABLE), enemy.stats.get_status(Stats.VULNERABLE) >= 0])

	# 截图：玩家力量 + 敌人易伤
	battle.player.stats.add_status(Stats.STRENGTH, 2)
	battle.player.stats.add_status(Stats.VULNERABLE, 1)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	print("SHOT %d" % img.save_png("res://shots/s_status.png"))

	get_tree().quit()
