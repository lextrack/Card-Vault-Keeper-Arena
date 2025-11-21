extends Control

signal battle_won
signal battle_lost
signal run_completed

@onready var ui_layer = $UILayer
@onready var transition_label = $UILayer/CenterContainer/ContentPanel/MarginContainer/VBoxContainer/TransitionLabel
@onready var status_label = $UILayer/CenterContainer/ContentPanel/MarginContainer/VBoxContainer/StatusLabel
@onready var progress_bar = $UILayer/CenterContainer/ContentPanel/MarginContainer/VBoxContainer/ProgressContainer/ProgressBar
@onready var progress_label = $UILayer/CenterContainer/ContentPanel/MarginContainer/VBoxContainer/ProgressContainer/ProgressLabel
@onready var enemy_info_container = $UILayer/CenterContainer/ContentPanel/MarginContainer/VBoxContainer/EnemyInfoContainer
@onready var enemy_type_label = $UILayer/CenterContainer/ContentPanel/MarginContainer/VBoxContainer/EnemyInfoContainer/EnemyTypeLabel
@onready var enemy_name_label = $UILayer/CenterContainer/ContentPanel/MarginContainer/VBoxContainer/EnemyInfoContainer/EnemyNameLabel
@onready var enemy_effect_label = $UILayer/CenterContainer/ContentPanel/MarginContainer/VBoxContainer/EnemyInfoContainer/EnemyEffectLabel

var run_state: RunState
var current_enemy: EnemyData
var run_battle_scene = preload("res://scenes/RunBattle.tscn")
var card_reward_scene = preload("res://scenes/CardRewardScreen.tscn")

var _tree: SceneTree
var is_transitioning: bool = false
var _battle_instance_ref: WeakRef = null

func _ready():
	_tree = get_tree()
	
	if TransitionManager and TransitionManager.current_overlay:
		await TransitionManager.current_overlay.fade_out(0.5)
	
	await _tree.create_timer(0.3).timeout
	
	start_new_run()

func start_new_run():
	run_state = RunState.new()
	run_state.reset()
	
	EnemyDatabase.reset_used_enemies()
	
	await update_loading_progress("Generating starter deck...", 0)
	await _tree.create_timer(0.3).timeout
	
	generate_initial_deck()
	
	await update_loading_progress("Initializing player stats...", 33)
	await _tree.create_timer(0.2).timeout
	
	run_state.player_hp = 50
	run_state.player_max_hp = 50
	
	await update_loading_progress("Preparing first battle...", 66)
	await _tree.create_timer(0.2).timeout
	
	await update_loading_progress("Ready!", 100)
	await _tree.create_timer(0.4).timeout
	
	start_next_battle()

func update_loading_progress(message: String, percentage: int):
	if is_instance_valid(status_label):
		status_label.text = message
	
	if is_instance_valid(progress_bar):
		var tween = create_tween()
		tween.tween_property(progress_bar, "value", float(percentage), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	if is_instance_valid(progress_label):
		progress_label.text = "%d%%" % percentage
	
	await _tree.create_timer(0.1).timeout

func generate_initial_deck():
	if not CardDatabase:
		push_error("[RunManager] CardDatabase not found!")
		return
	
	var starter_deck = CardDatabase.get_random_run_starter_deck()
	
	if not starter_deck or starter_deck.size() == 0:
		push_error("[RunManager] Failed to generate starter deck!")
		return
	
	run_state.player_deck_card_names.clear()
	for card in starter_deck:
		if card and card is CardData:
			run_state.player_deck_card_names.append(card.card_name)
	
	print("[RunManager] Generated starter deck with %d cards" % run_state.player_deck_card_names.size())

func start_next_battle():
	if is_transitioning:
		return
	
	is_transitioning = true
	var is_boss = not run_state.is_minion_phase()
	
	if run_state.is_minion_phase():
		current_enemy = EnemyDatabase.get_random_minion()
		run_state.active_negative_effect = ""
		run_state.active_negative_effect_description = ""
	else:
		current_enemy = EnemyDatabase.get_random_boss()
		run_state.active_negative_effect = current_enemy.negative_effect
		run_state.active_negative_effect_description = current_enemy.negative_effect_description
	
	run_state.current_enemy_name = current_enemy.enemy_name
	run_state.enemies_faced.append(current_enemy.enemy_name)
	
	await show_battle_preview(current_enemy, is_boss)
	await _tree.create_timer(1.5).timeout
	
	if TransitionManager and TransitionManager.current_overlay:
		await TransitionManager.current_overlay.fade_in(0.4)
	
	load_battle_scene()

func show_battle_preview(enemy: EnemyData, is_boss: bool):
	if is_instance_valid(progress_bar):
		progress_bar.visible = false
	if is_instance_valid(progress_label):
		progress_label.visible = false
	
	if is_instance_valid(transition_label):
		transition_label.text = "Entering Battle..."
	
	if is_instance_valid(status_label):
		status_label.text = run_state.get_progress_text()
	
	if is_instance_valid(enemy_info_container):
		enemy_info_container.visible = true
		
		if is_instance_valid(enemy_type_label):
			if is_boss:
				enemy_type_label.text = "BOSS BATTLE"
				enemy_type_label.modulate = Color(1.0, 0.8, 0.3, 1.0)
			else:
				enemy_type_label.text = "MINION BATTLE"
				enemy_type_label.modulate = Color(0.8, 0.8, 1.0, 1.0)
		
		if is_instance_valid(enemy_name_label):
			enemy_name_label.text = enemy.get_display_name()
		
		if is_instance_valid(enemy_effect_label):
			if enemy.negative_effect != "":
				enemy_effect_label.text = enemy.negative_effect_description
				enemy_effect_label.visible = true
			else:
				enemy_effect_label.visible = false
		
		var tween = create_tween()
		tween.set_parallel(true)
		enemy_info_container.modulate.a = 0.0
		tween.tween_property(enemy_info_container, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
		tween.tween_property(enemy_info_container, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).from(Vector2(0.8, 0.8))

func load_battle_scene():
	print("[RunManager] Loading battle scene...")
	
	var battle_instance = run_battle_scene.instantiate()
	_battle_instance_ref = weakref(battle_instance)
	
	battle_instance.battle_won.connect(_on_battle_won)
	battle_instance.battle_lost.connect(_on_battle_lost)
	
	print("[RunManager] Signals connected")
	
	get_tree().root.add_child(battle_instance)
	
	battle_instance.initialize_run_battle(run_state, current_enemy)
	
	print("[RunManager] Battle initialized")
	
	if TransitionManager and TransitionManager.current_overlay:
		await TransitionManager.current_overlay.fade_out(0.4)
	
	hide()
	is_transitioning = false

func _on_battle_won(remaining_hp: int):
	print("[RunManager] Battle won! HP remaining: %d" % remaining_hp)
	
	run_state.player_hp = remaining_hp
	
	var next_phase = run_state.advance_phase()
	
	print("[RunManager] Next phase: %s" % next_phase)
	
	if TransitionManager and TransitionManager.current_overlay:
		await TransitionManager.current_overlay.fade_in(0.3)
	
	_cleanup_battle_scene()
	
	if next_phase == "victory":
		await show_run_victory()
	elif next_phase == "boss":
		show()
		if TransitionManager and TransitionManager.current_overlay:
			await TransitionManager.current_overlay.fade_out(0.3)
		reset_ui_for_new_battle()
		start_next_battle()
	elif next_phase == "minion":
		await show_card_reward()

func reset_ui_for_new_battle():
	if is_instance_valid(enemy_info_container):
		enemy_info_container.visible = false
	
	if is_instance_valid(progress_bar):
		progress_bar.visible = true
		progress_bar.value = 0
	
	if is_instance_valid(progress_label):
		progress_label.visible = true
		progress_label.text = "0%"

func _cleanup_battle_scene():
	if _battle_instance_ref:
		var battle = _battle_instance_ref.get_ref()
		if battle and is_instance_valid(battle):
			if battle.has_method("_cleanup_scene"):
				battle._cleanup_scene()
			
			if battle.battle_won.is_connected(_on_battle_won):
				battle.battle_won.disconnect(_on_battle_won)
			if battle.battle_lost.is_connected(_on_battle_lost):
				battle.battle_lost.disconnect(_on_battle_lost)
			
			battle.queue_free()
			await get_tree().process_frame
		_battle_instance_ref = null

func _on_battle_lost():
	print("[RunManager] Battle lost!")
	
	if TransitionManager and TransitionManager.current_overlay:
		await TransitionManager.current_overlay.fade_in(0.3)
	
	_cleanup_battle_scene()
	
	await show_run_defeat()

func show_card_reward():
	print("[RunManager] Showing card reward screen...")
	
	show()
	if is_instance_valid(transition_label):
		transition_label.text = "Victory!"
	if is_instance_valid(status_label):
		status_label.text = "Choose your reward..."
	if is_instance_valid(enemy_info_container):
		enemy_info_container.visible = false
	
	await _tree.create_timer(0.8).timeout
	
	if TransitionManager and TransitionManager.current_overlay:
		await TransitionManager.current_overlay.fade_in(0.3)
	
	var reward_screen = card_reward_scene.instantiate()
	get_tree().root.add_child(reward_screen)
	
	reward_screen.card_selected.connect(_on_card_reward_selected)
	reward_screen.show_rewards(run_state.get_deck_size())

	
	await _tree.create_timer(0.1).timeout
	
	if TransitionManager and TransitionManager.current_overlay:
		await TransitionManager.current_overlay.fade_out(0.4)
	
	hide()

func _on_card_reward_selected(card_name: String):
	print("[RunManager] Card selected: %s" % card_name)
	
	run_state.add_card_to_deck(card_name)
	
	print("[RunManager] Deck now has %d cards" % run_state.get_deck_size())
	
	if TransitionManager and TransitionManager.current_overlay:
		await TransitionManager.current_overlay.fade_in(0.3)
	
	for child in get_tree().root.get_children():
		if child.name == "CardRewardScreen":
			child.queue_free()
			await get_tree().process_frame
			break
	
	show()
	reset_ui_for_new_battle()
	
	if TransitionManager and TransitionManager.current_overlay:
		await TransitionManager.current_overlay.fade_out(0.3)
	
	start_next_battle()

func show_run_victory():
	print("[RunManager] RUN COMPLETED!")
	
	show()
	
	if is_instance_valid(transition_label):
		transition_label.text = "RUN COMPLETED!"
		transition_label.modulate = Color(1.0, 1.0, 0.3, 1.0)
	
	if is_instance_valid(status_label):
		status_label.text = "You defeated all enemies!\nCongratulations!"
	
	if is_instance_valid(enemy_info_container):
		enemy_info_container.visible = false
	
	if TransitionManager and TransitionManager.current_overlay:
		await TransitionManager.current_overlay.fade_out(0.5)
	
	await _tree.create_timer(2.0).timeout
	
	return_to_menu()

func show_run_defeat():
	print("[RunManager] RUN FAILED!")
	
	show()
	
	if is_instance_valid(transition_label):
		transition_label.text = "DEFEAT"
		transition_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
	
	if is_instance_valid(status_label):
		status_label.text = "Your run has ended...\nBetter luck next time!"
	
	if is_instance_valid(enemy_info_container):
		enemy_info_container.visible = false
	
	if TransitionManager and TransitionManager.current_overlay:
		await TransitionManager.current_overlay.fade_out(0.5)
	
	await _tree.create_timer(2.0).timeout
	
	return_to_menu()

func return_to_menu():
	print("[RunManager] Returning to main menu...")
	
	if TransitionManager:
		await TransitionManager.fade_to_main_menu(1.0)
	else:
		_tree.change_scene_to_file("res://scenes/MainMenu.tscn")
