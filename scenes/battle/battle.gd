class_name Battle
extends Node2D

## 战斗指挥：敌人意图、结算、回合节奏、胜负、手感（震屏/红屏/音效）。

@onready var player: Player = $Player
@onready var hand: HBoxContainer = $UILayer/Hand
@onready var handler: PlayerHandler = $PlayerHandler
@onready var top_bar: TopBar = $UILayer/TopBar
@onready var pile_view: CardPileView = $UILayer/CardPileView
@onready var flash: ColorRect = $UILayer/Flash
@onready var over_panel: BattleOverPanel = $UILayer/BattleOverPanel
@onready var pause_button: Button = $UILayer/Pause
@onready var pause_label: Label = $UILayer/PauseLabel
@onready var help_button: Button = $UILayer/Help
@onready var help_panel: PanelContainer = $UILayer/HelpPanel
@onready var help_close: Button = $UILayer/HelpPanel/HelpBox/HelpHeader/HelpClose
@onready var rewards: CardRewards = $UILayer/CardRewards

## P38：敌人种类。视频里是 bat / crab 的组合，这里用同一个场景 + 不同贴图与系数
const ENEMY_KINDS := {
	"bat": {"art": "res://art/tile_0107.png", "hp": 0.75, "damage": 0.8},
	"crab": {"art": "res://art/tile_0108.png", "hp": 1.15, "damage": 1.0},
}

var enemy_turn := false
var battle_over := false
var round_index := 1


func _ready() -> void:
	Shaker.register_target(self)

	top_bar.end_turn_pressed.connect(end_turn)
	pause_button.pressed.connect(_toggle_pause)
	help_button.pressed.connect(func() -> void: help_panel.visible = not help_panel.visible)
	help_close.pressed.connect(func() -> void: help_panel.visible = false)
	pause_button.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_label.process_mode = Node.PROCESS_MODE_ALWAYS
	over_panel.restart_requested.connect(func() -> void: get_tree().reload_current_scene())
	over_panel.continue_requested.connect(_go_next_room)

	top_bar.draw_pressed.connect(func() -> void:
		pile_view.toggle("抽牌堆", handler.draw_pile.cards))
	top_bar.discard_pressed.connect(func() -> void:
		pile_view.toggle("弃牌堆", handler.discard_pile.cards))

	player.setup(_player_stats())
	player.stats.stats_changed.connect(_refresh_affordability)
	player.stats.stats_changed.connect(_refresh_energy_bar)
	player.died.connect(_on_player_died)

	# P37/P38：先抽一场遭遇战再摆敌人（具体几个、多硬由 BattleStats 决定）
	_spawn_encounter()

	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.setup(_enemy_stats(enemy.name, enemy.get_meta("kind", "crab")))
		# 敌人一死就检查胜负：不管它是被卡打死、被效果烧死，还是被测试直接打死的
		enemy.died.connect(_on_enemy_died)

	handler.setup(player, hand, $UILayer)
	handler.piles_changed.connect(_update_piles)
	handler.card_played.connect(_on_play_requested)
	handler.build_deck(_current_deck())

	_update_piles()
	# P13：手牌没抽完之前不能结束回合（视频里是 player_hand_drawn 事件解禁）
	top_bar.set_end_enabled(false)
	await handler.start_turn()
	RunState.turn_start_hooks(player)      # P37：每回合开始类遗物
	top_bar.set_end_enabled(true)
	_refresh_affordability()
	_pick_intents()


# ---------- 回合 ----------

func end_turn() -> void:
	if enemy_turn or battle_over:
		return
	enemy_turn = true
	top_bar.set_end_enabled(false)

	handler.discard_hand()
	player.stats.tick_statuses()          # 玩家回合结束：自己的状态扣一层

	for enemy in get_tree().get_nodes_in_group("enemies"):
		# P14：敌人按上一轮抽好的意图行动（扑过去 → 结算 → 收招）
		await enemy.execute(player)
		if enemy.current_action and enemy.current_action.type == EnemyAction.Type.ATTACK:
			Sfx.play("enemy_attack")
			_flash_screen(Color(0.85, 0.12, 0.12, 0.32), 0.22)
			Shaker.shake(3.0, 0.2)
		if enemy.get("stats") is Stats:
			enemy.stats.tick_statuses()   # 敌人行动完，自己的状态扣一层
		await get_tree().create_timer(0.22).timeout
		if player.stats.health <= 0:
			_lose()
			return

	round_index += 1
	enemy_turn = false
	top_bar.set_end_enabled(false)        # 抽牌期间先关掉
	await handler.start_turn()
	RunState.turn_start_hooks(player)
	top_bar.set_end_enabled(true)
	_refresh_affordability()
	_pick_intents()


func _pick_intents() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.pick_intent()


# ---------- 结算 ----------

func _on_play_requested(card_ui: CardUI, targets: Array) -> void:
	if battle_over or card_ui.card == null:
		return
	if not player.spend_energy(card_ui.card.cost):
		# 别默默弹回去：告诉玩家为什么打不出去
		Fx.pop_number(card_ui.global_position + card_ui.size * 0.5, card_ui.card.cost, Color(1.0, 0.45, 0.4), 1.2)
		_hint("能量不够")
		card_ui.return_home()
		return

	card_ui.card.apply(targets, player.stats)
	Sfx.play("slash" if card_ui.card.type == Card.Type.ATTACK else "block")
	Shaker.shake(2.0, 0.12)
	handler.discard(card_ui)
	_refresh_affordability()
	_update_piles()

	await get_tree().process_frame
	_check_victory()


func _check_victory() -> void:
	if battle_over:
		return
	if get_tree().get_nodes_in_group("enemies").is_empty():
		_win()


func _on_enemy_died() -> void:
	# queue_free 是延迟的，等一帧再数，否则还会数到这只正在死的敌人
	await get_tree().process_frame
	_check_victory()


func _win() -> void:
	battle_over = true
	top_bar.set_end_enabled(false)
	handler.clear_hand_instant()
	# P39：血量带出战斗，营地才有意义
	RunState.current_health = player.stats.health

	# P28/P29：金币 + 三选一。奖励先弹出来，收下之后才给"继续前进"
	var gold := RunState.current_encounter.roll_gold() if RunState.current_encounter else randi_range(10, 20)
	RunState.add_gold(gold)

	# P37：精英/Boss 额外掉一个遗物
	var got_relic := ""
	if RunState.current_room_type() in [Room.Type.ELITE, Room.Type.BOSS]:
		var relic := RelicLibrary.random_reward()
		RunState.add_relic(relic)
		got_relic = relic.title

	_update_piles()
	rewards.closed.connect(_on_rewards_closed.bind(got_relic), CONNECT_ONE_SHOT)
	rewards.open(RewardPool.draw(3), gold)


func _on_rewards_closed(got_relic := "") -> void:
	var extra := " · 遗物 %s" % got_relic if not got_relic.is_empty() else ""
	over_panel.show_result(true, "第 %d 回合 · 金币 %d · 卡组 %d 张%s" % [
		round_index, RunState.gold, RunState.deck.size(), extra])


func _lose() -> void:
	battle_over = true
	top_bar.set_end_enabled(false)
	over_panel.show_result(false, "第 %d 回合被打倒" % round_index)


func _on_player_died() -> void:
	if not battle_over:
		_lose()


func _update_piles() -> void:
	top_bar.set_piles(handler.draw_pile.size(), handler.discard_pile.size())
	if RunState.character:
		top_bar.set_depth(RunState.depth)
		top_bar.set_gold(RunState.gold)


func _refresh_affordability() -> void:
	var energy: int = player.stats.energy
	for child in hand.get_children():
		var card_ui := child as CardUI
		if card_ui and card_ui.card:
			card_ui.set_affordable(card_ui.card.cost <= energy)


# ---------- 手感 ----------

func _flash_screen(color: Color, duration: float) -> void:
	flash.color = color
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.0, duration)


func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	pause_label.visible = get_tree().paused


# ---------- 数值 ----------

func _player_stats() -> CharacterStats:
	var stats := CharacterStats.new()
	if RunState.character == null:
		RunState.reset()
	# P21/P23：血量、能量都来自"当前角色 + 遗物"，Battle 不再自己写死 35/3
	RunState.apply_to(stats)
	return stats


## 卡组也是从 RunState 拿（奖励、商店会往里加卡）
func _current_deck() -> Array[Card]:
	if RunState.deck.is_empty():
		RunState.reset()
	var out: Array[Card] = []
	for card in RunState.deck:
		out.append(card)
	return out


## 打赢了：回地图（P31 之后由地图决定下一个房间）
func _go_next_room() -> void:
	RunState.depth += 1
	get_tree().change_scene_to_file("res://scenes/map/map.tscn")


func _spawn_encounter() -> void:
	# P38：房间自带遭遇战就用它（地图生成时已经抽好），否则临时抽一场
	var encounter: BattleStats = null
	if RunState.current_room >= 0 and RunState.current_room < RunState.map_rooms.size():
		encounter = (RunState.map_rooms[RunState.current_room] as Room).battle_stats
	if encounter == null:
		var elite := RunState.current_room_type() in [Room.Type.ELITE, Room.Type.BOSS]
		encounter = BattlePool.pick(RunState.depth, elite)
	RunState.current_encounter = encounter

	var scene: PackedScene = load("res://scenes/enemy/enemy.tscn")
	var count := maxi(1, encounter.enemy_count)
	for i in count:
		var enemy := scene.instantiate()
		# 三只时排成三角，两只并排，一只居中
		var t := 0.0 if count == 1 else float(i) / float(count - 1)
		enemy.position = Vector2(lerpf(150.0, 218.0, t), lerpf(56.0, 68.0, t))
		$EnemyHandler.add_child(enemy)


func _enemy_stats(display_name: String, kind := "crab") -> EnemyStats:
	var stats := EnemyStats.new()
	stats.display_name = display_name

	# P37/P38：战斗随机化——越深越硬，且每场有浮动，不能靠背板通关
	var depth_scale := 1.0 + 0.15 * maxf(0.0, RunState.depth - 1)
	# P34/P38：房间类型决定强敌倍率（精英 1.5×、Boss 2.4×）
	var room_scale := 1.0
	match RunState.current_room_type():
		Room.Type.ELITE:
			room_scale = 1.5
		Room.Type.BOSS:
			room_scale = 2.4
	var scale := depth_scale * room_scale

	# P37：遭遇战自己的倍率（数量之外的强度差异）
	var encounter := RunState.current_encounter
	var hp_mult := encounter.hp_multiplier if encounter else 1.0
	var dmg_mult := encounter.damage_multiplier if encounter else 1.0

	var hp := int(round(18.0 * scale * hp_mult * randf_range(0.9, 1.1)))
	# P38：种类差异（bat 脆、crab 硬），贴图也跟着换
	var kind_data: Dictionary = ENEMY_KINDS.get(kind, ENEMY_KINDS["crab"])
	hp = int(round(hp * float(kind_data["hp"])))
	stats.art = load(kind_data["art"])
	dmg_mult *= float(kind_data["damage"])
	stats.max_health = maxi(6, hp)
	stats.health = stats.max_health

	# P14：动作表 —— 普攻重、重击第 2 回合才可能出、格挡第 3 回合才可能出
	var basic := EnemyAction.new()
	basic.type = EnemyAction.Type.ATTACK
	basic.value = maxi(2, int(round(6.0 * scale * dmg_mult * randf_range(0.9, 1.1))))
	basic.weight = 3.0

	var heavy := EnemyAction.new()
	heavy.type = EnemyAction.Type.ATTACK
	heavy.value = maxi(3, int(round(9.0 * scale * dmg_mult)))
	heavy.weight = 1.5
	heavy.min_turn = 2

	var guard := EnemyAction.new()
	guard.type = EnemyAction.Type.BLOCK
	guard.value = maxi(3, int(round(5.0 * scale * dmg_mult * 0.6)))
	guard.weight = 1.0
	guard.min_turn = 3

	stats.actions.append(basic)
	stats.actions.append(heavy)
	stats.actions.append(guard)
	return stats


# ---------- 起手牌 ----------

## 卡牌定义集中在 CardLibrary（P21），战斗只拿实例
func build_starting_deck() -> Array[Card]:
	return _current_deck()

## 打开帮助后按 Esc 也能关（面板会盖住「玩法」按钮，必须有第二出口）
func _unhandled_input(event: InputEvent) -> void:
	if help_panel.visible and event.is_action_pressed("ui_cancel"):
		help_panel.visible = false
		get_viewport().set_input_as_handled()

## 战斗里的短提示（能量不够、要选目标之类）
func _hint(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1.0, 0.62, 0.5))
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.05))
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 130
	Fx.layer.add_child(label)
	label.position = Vector2(128 - label.get_minimum_size().x * 0.5, 96)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 8.0, 0.7)
	tween.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tween.chain().tween_callback(label.queue_free)

## 顶栏能量（每次 stats_changed 都会走到）
func _refresh_energy_bar() -> void:
	if is_instance_valid(player) and player.stats:
		top_bar.set_energy(player.stats.energy, player.stats.max_energy)