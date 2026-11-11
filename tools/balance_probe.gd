extends Node

## 平衡探针：按真实代码生成各深度的敌人，算出「几回合能杀完」和「几回合会被打死」。
## 模型假设玩家 4 能量：
##   全力进攻 = 4×打击 = 24 伤/回合
##   攻守平衡 = 3×打击 + 1×防御 = 18 伤 + 5 挡
## 结论判据：能杀完的回合数 < 能活的回合数，才算打得赢。

const SAMPLES := 8
const PLAYER_DMG := 18.0     # 攻守平衡下的每回合输出
const PLAYER_BLOCK := 5.0    # 每回合挡掉的伤害


func _ready() -> void:
	print("深度 | 敌总血 | 每回合挨打 | 玩家血 | 杀完回合 | 能活回合 | 判定")
	print("-----|--------|------------|--------|----------|----------|-----")
	for d in [1, 3, 5, 7, 9, 11, 13, 15]:
		RunState.depth = d
		var hp_sum := 0.0
		var dmg_sum := 0.0
		var php := 0.0
		var got := 0
		for s in SAMPLES:
			var packed: PackedScene = load("res://scenes/battle/battle.tscn")
			var b: Node = packed.instantiate()
			add_child(b)
			await get_tree().create_timer(0.35).timeout
			var enemies := get_tree().get_nodes_in_group("enemies")
			if enemies.is_empty():
				b.queue_free()
				await get_tree().process_frame
				continue
			for e in enemies:
				hp_sum += float(e.stats.max_health)
				# 取普攻（第一条动作）当作每回合的压力
				if e.stats.actions.size() > 0:
					dmg_sum += float(e.stats.actions[0].value)
			php = float(b.player.stats.max_health)
			got += 1
			b.queue_free()
			await get_tree().process_frame
		if got == 0:
			print("%4d | 采样失败" % d)
			continue
		var hp := hp_sum / got
		var incoming := dmg_sum / got
		var ttk := hp / PLAYER_DMG
		var net := maxf(1.0, incoming - PLAYER_BLOCK)
		var tts := php / net
		var verdict := "OK" if ttk < tts else "FAIL"
		print("%4d | %6.0f | %10.1f | %6.0f | %8.1f | %8.1f | %s" % [d, hp, incoming, php, ttk, tts, verdict])
	get_tree().quit()
