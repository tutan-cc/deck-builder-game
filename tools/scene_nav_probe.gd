extends Node

## 全流程导航探针：真的调用 change_scene_to_file 走一遍
##   主菜单 → 选角色 → 剧本 → 地图 → 战斗
## 关键技巧：把自己挂到 root 上，这样切场景不会把测试节点一起销毁
## （普通节点是当前场景的子节点，切场景就被 free 了）。


func _ready() -> void:
	# _ready 执行期间父节点处于 busy 状态，不能 remove_child。
	# 先让出一帧，再把自己挂到 root 上——之后切场景就销毁不到我们了。
	await get_tree().process_frame
	# remove_child 之后自己就不在树里了，get_tree() 会返回 null —— 先缓存
	var tree := get_tree()
	var parent := get_parent()
	if parent:
		parent.remove_child(self)
	tree.root.add_child(self)
	_run()


func _run() -> void:
	RunState.start_run(Character.warrior())
	print("NAV start: deck=%d hp=%d depth=%d" % [RunState.deck.size(), RunState.current_health, RunState.depth])

	await _goto("res://scenes/ui/main_menu.tscn")
	print("NAV  deck kept across main_menu: %d" % RunState.deck.size())

	await _goto("res://scenes/ui/character_selector.tscn")

	# 从选角色界面真的开始一局：走它自己的入口（go_button → _start）
	var cs := get_tree().current_scene
	if cs and cs.has_method("_start"):
		cs._select(Character.warrior())
		await get_tree().process_frame
		cs._start()
		await get_tree().create_timer(0.9).timeout
		print("NAV  after _start: scene=%s deck=%d" % [
			get_tree().current_scene.name if get_tree().current_scene else "null", RunState.deck.size()])
	else:
		print("NAV  character_selector: 没有 _start，跳过")

	await _goto("res://scenes/map/map.tscn")

	# 地图 → 战斗：挑一间战斗房
	var idx := -1
	for i in RunState.map_rooms.size():
		if RunState.map_rooms[i].type == Room.Type.BATTLE:
			idx = i
			break
	if idx < 0:
		print("NAV 地图里没有战斗房")
		get_tree().quit()
		return
	RunState.current_room = idx
	RunState.depth = RunState.map_rooms[idx].row + 1
	var deck_before := RunState.deck.size()
	await _goto("res://scenes/battle/battle.tscn")

	var enemies := get_tree().get_nodes_in_group("enemies")
	print("NAV  battle: enemies=%d deck_kept=%d (before=%d)" % [enemies.size(), RunState.deck.size(), deck_before])

	# 打赢，看结算面板
	for e in enemies:
		e.stats.take_damage(999)
	await get_tree().create_timer(1.2).timeout
	var battle := get_tree().current_scene
	if battle and battle.get("rewards"):
		# 胜利流程是「先三选一奖励，收下之后才显示结算面板」
		# 不领奖励直接看 over_panel 一定是 false —— 那是正确行为，不是 bug
		print("NAV  victory: rewards_open=%s deck=%d gold=%d" % [
			battle.rewards.visible, RunState.deck.size(), RunState.gold])
		var first: CardUI = battle.rewards.row.get_child(0)
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = true
		var deck_before_reward := RunState.deck.size()
		battle.rewards._on_card_input(ev, first.card, first)
		await get_tree().create_timer(0.6).timeout
		print("NAV  after reward: deck %d -> %d, panel=%s" % [
			deck_before_reward, RunState.deck.size(), battle.over_panel.visible])
		# 走"继续"，验证能回到下一个场景
		battle.over_panel.continue_requested.emit()
		await get_tree().create_timer(0.9).timeout
		var nxt := get_tree().current_scene
		print("NAV  after continue: scene=%s" % (nxt.name if nxt else "null"))

	get_tree().quit()


func _goto(path: String) -> void:
	var err := get_tree().change_scene_to_file(path)
	await get_tree().create_timer(0.8).timeout
	var cur := get_tree().current_scene
	print("NAV  -> %-28s err=%d scene=%s" % [path.get_file(), err, cur.name if cur else "null"])
