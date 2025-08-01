extends Control

@onready var stats_label = $MainContainer/HeaderContainer/StatsLabel
@onready var bundles_grid = $MainContainer/ContentContainer/BundlesPanel/BundlesScrollContainer/BundlesGrid
@onready var bundles_scroll_container = $MainContainer/ContentContainer/BundlesPanel/BundlesScrollContainer
@onready var ai_avatar = $MainContainer/ContentContainer/AIContainer/AIPanel/AIContent/AICharacterContainer/AIAvatar
@onready var dialog_text = $MainContainer/ContentContainer/AIContainer/AIPanel/AIContent/AIDialogContainer/DialogBubble/DialogBox/DialogText
@onready var dialog_bg = $MainContainer/ContentContainer/AIContainer/AIPanel/AIContent/AIDialogContainer/DialogBubble/DialogBox/DialogBG
@onready var status_light = $MainContainer/ContentContainer/AIContainer/AIPanel/AIContent/AIDialogContainer/DialogBubble/DialogBox/StatusLight
@onready var typing_indicator = $MainContainer/ContentContainer/AIContainer/AIPanel/AIContent/AIDialogContainer/DialogBubble/DialogBox/TypingIndicator
@onready var back_button = $MainContainer/ButtonsContainer/BackButton
@onready var refresh_button = $MainContainer/ButtonsContainer/RefreshButton
@onready var debug_button = $MainContainer/ButtonsContainer/DebugButton
@onready var ui_player = $AudioManager/UIPlayer
@onready var hover_player = $AudioManager/HoverPlayer

var challenge_music_stream = preload("res://audio/music/challenge_hub_theme.ogg")
var robot_head_scene = preload("res://scenes/RobotHead.tscn")
var robot_head_instance: RobotHead

var bundle_card_scene = preload("res://scenes/BundleCard.tscn")
var bundle_card_instances: Array = []
var is_transitioning: bool = false
var accessed_from_game: bool = false
var debug_mode_unlock = true

var gamepad_mode: bool = false
var selected_bundle_index: int = 0
var last_input_was_gamepad: bool = false
var scroll_speed: float = 200.0
var input_cooldown: float = 0.0
var input_cooldown_time: float = 0.15

var dialog_timer: Timer
var current_dialog_queue: Array = []

var layout_config: Dictionary = {}

var intro_dialogs = [
	"Welcome to my collection vault!",
	"I am the keeper of these powerful card bundles...",
	"Complete the challenges and these cards will be yours."
]

var casual_dialogs = [
	"Browse at your leisure...",
	"Some challenges are harder than others, but the rewards match.",
	"Every great warrior needs the right tools...",
	"Shield cards have saved more battles than most realize.",
	"When we duel, I'll use some of these very cards against you...",
	"The cards are watching your progress with interest...",
	"I've seen warriors fall because they ignored defensive cards.",
	"Every card in my vault has proven its worth in battle.",
	"Have you checked what you need to do to unlock the next bundle? Then start a game, I'm looking forward to fighting with you."
]

func _ready():
	accessed_from_game = GameStateManager.has_saved_state()
	
	setup_ui()
	setup_ai_character()
	setup_dialog_system()
	setup_gamepad_navigation()
	setup_challenge_music()
	
	call_deferred("setup_layout")
	
	if accessed_from_game:
		back_button.text = "BACK TO GAME"
		var game_age = GameStateManager.get_save_age_seconds()
		if game_age >= 0 and game_age < 60:
			queue_dialog_sequence(["Your game is waiting... Take your time browsing!"])
		else:
			queue_dialog_sequence(["Ahh, you're back!"])
	else:
		back_button.text = "BACK"
	
	await handle_scene_entrance()
	
	load_shop_data()
	
	if not accessed_from_game:
		var first_visit = load_first_visit_status()
		if first_visit:
			queue_dialog_sequence(intro_dialogs)
			save_first_visit_status(false)
		else:
			queue_dialog_sequence([casual_dialogs[randi() % casual_dialogs.size()]])

func _process(delta):
	if input_cooldown > 0:
		input_cooldown -= delta

func setup_challenge_music():
	if GlobalMusicManager:
		GlobalMusicManager.set_challenge_music_stream(challenge_music_stream)
		
		if not accessed_from_game:
			GlobalMusicManager.start_challenge_music(1.0)
		else:
			await get_tree().create_timer(0.5).timeout
			GlobalMusicManager.start_challenge_music(2.0)
		
func load_first_visit_status() -> bool:
	if FileAccess.file_exists("user://challenge_visited.save"):
		return false
	else:
		return true 

func save_first_visit_status(is_first_visit: bool):
	if not is_first_visit:
		var file = FileAccess.open("user://challenge_visited.save", FileAccess.WRITE)
		if file:
			file.store_string("visited")
			file.close()

func setup_gamepad_navigation():
	back_button.set_focus_neighbor(SIDE_RIGHT, refresh_button.get_path())
	refresh_button.set_focus_neighbor(SIDE_LEFT, back_button.get_path())
	
	if debug_button.visible:
		refresh_button.set_focus_neighbor(SIDE_RIGHT, debug_button.get_path())
		debug_button.set_focus_neighbor(SIDE_LEFT, refresh_button.get_path())
		debug_button.set_focus_neighbor(SIDE_RIGHT, back_button.get_path())
	else:
		refresh_button.set_focus_neighbor(SIDE_RIGHT, back_button.get_path())
	
	back_button.set_focus_neighbor(SIDE_BOTTOM, bundles_scroll_container.get_path())
	bundles_scroll_container.set_focus_neighbor(SIDE_TOP, back_button.get_path())
	
	bundles_scroll_container.focus_mode = Control.FOCUS_ALL
	
	bundles_scroll_container.focus_entered.connect(_on_bundles_focus_entered)
	bundles_scroll_container.focus_exited.connect(_on_bundles_focus_exited)
	
	for button in [back_button, refresh_button, debug_button]:
		if button.visible:
			button.focus_entered.connect(_on_button_focused.bind(button))
			button.focus_exited.connect(_on_button_unfocused.bind(button))

func _on_button_focused(button: Button):
	_enter_mouse_mode()

func _on_button_unfocused(button: Button):
	pass

func _on_bundles_focus_entered():
	_enter_gamepad_mode()

func _on_bundles_focus_exited():
	_exit_gamepad_mode()

func _enter_gamepad_mode():
	if not gamepad_mode:
		gamepad_mode = true
		selected_bundle_index = 0
		update_bundle_selection()

func _exit_gamepad_mode():
	clear_bundle_selection()

func _enter_mouse_mode():
	if gamepad_mode:
		gamepad_mode = false
		clear_bundle_selection()

func _detect_input_method(event: InputEvent):
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if not gamepad_mode and (event is InputEventJoypadButton and event.pressed):
			last_input_was_gamepad = true
			_enter_gamepad_mode()
			if bundle_card_instances.size() > 0:
				bundles_scroll_container.grab_focus()
	elif (event is InputEventMouse and event.is_pressed()) or (event is InputEventKey and event.is_pressed()):
		if gamepad_mode:
			last_input_was_gamepad = false
			_enter_mouse_mode()
			if bundles_scroll_container.has_focus():
				bundles_scroll_container.release_focus()

func update_bundle_selection():
	if not gamepad_mode or bundle_card_instances.size() == 0:
		return
	
	if selected_bundle_index < 0 or selected_bundle_index >= bundle_card_instances.size():
		selected_bundle_index = 0
	
	for i in range(bundle_card_instances.size()):
		var bundle_card = bundle_card_instances[i]
		if is_instance_valid(bundle_card):
			bundle_card.modulate = Color.WHITE
			bundle_card.z_index = 0
			bundle_card.scale = Vector2(1.0, 1.0)
	
	var selected_bundle = bundle_card_instances[selected_bundle_index]
	if is_instance_valid(selected_bundle):
		selected_bundle.modulate = Color(1.2, 1.2, 0.9, 1.0)
		selected_bundle.z_index = 10
		selected_bundle.scale = Vector2(1.05, 1.05)
		
		ensure_bundle_visible(selected_bundle_index)

func clear_bundle_selection():
	for bundle_card in bundle_card_instances:
		if is_instance_valid(bundle_card):
			bundle_card.modulate = Color.WHITE
			bundle_card.z_index = 0
			bundle_card.scale = Vector2(1.0, 1.0)

func ensure_bundle_visible(bundle_index: int):
	if bundle_index < 0 or bundle_index >= bundle_card_instances.size():
		return
	
	var selected_bundle = bundle_card_instances[bundle_index]
	if not is_instance_valid(selected_bundle) or not selected_bundle.is_inside_tree():
		return

	await get_tree().process_frame
	
	var bundle_rect = selected_bundle.get_rect()
	var bundle_global_pos = selected_bundle.global_position
	var scroll_rect = bundles_scroll_container.get_rect()
	var scroll_global_pos = bundles_scroll_container.global_position

	var bundle_top = bundle_global_pos.y - scroll_global_pos.y
	var bundle_bottom = bundle_top + bundle_rect.size.y
	var visible_top = bundles_scroll_container.scroll_vertical
	var visible_bottom = visible_top + scroll_rect.size.y
	
	var target_scroll = bundles_scroll_container.scroll_vertical
	
	if bundle_top < visible_top:
		target_scroll = max(0, bundle_top - 50)
	elif bundle_bottom > visible_bottom:
		target_scroll = bundle_bottom - scroll_rect.size.y + 50
	
	if target_scroll != bundles_scroll_container.scroll_vertical:
		var tween = create_tween()
		tween.tween_property(bundles_scroll_container, "scroll_vertical", target_scroll, 0.2)

func navigate_bundles(direction: Vector2) -> bool:
	if bundle_card_instances.size() == 0 or input_cooldown > 0:
		return false
	
	input_cooldown = input_cooldown_time
	
	var columns = layout_config.get("columns", 3)
	var current_row = selected_bundle_index / columns
	var current_col = selected_bundle_index % columns
	
	var new_index = selected_bundle_index
	
	match direction:
		Vector2.RIGHT:
			new_index = (selected_bundle_index + 1) % bundle_card_instances.size()
		Vector2.LEFT:
			new_index = (selected_bundle_index - 1 + bundle_card_instances.size()) % bundle_card_instances.size()
		Vector2.DOWN:
			var next_row_index = selected_bundle_index + columns
			if next_row_index < bundle_card_instances.size():
				new_index = next_row_index
			else:
				new_index = current_col
		Vector2.UP:
			var prev_row_index = selected_bundle_index - columns
			if prev_row_index >= 0:
				new_index = prev_row_index
			else:
				var last_row = (bundle_card_instances.size() - 1) / columns
				new_index = min(last_row * columns + current_col, bundle_card_instances.size() - 1)
	
	if new_index != selected_bundle_index:
		selected_bundle_index = new_index
		update_bundle_selection()
		play_hover_sound()
		return true
	
	return false

func activate_selected_bundle():
	if selected_bundle_index < 0 or selected_bundle_index >= bundle_card_instances.size():
		return
	
	var selected_bundle = bundle_card_instances[selected_bundle_index]
	if not is_instance_valid(selected_bundle):
		return
	
	var bundle_info = selected_bundle.bundle_info
	if bundle_info.is_empty():
		return
	
	if bundle_info.can_unlock:
		_on_bundle_unlock_requested(bundle_info.id)
	else:
		var progress_text = UnlockManagers.get_progress_text(bundle_info.id)
		queue_dialog_sequence(["You need to: " + bundle_info.requirement_text + " (" + progress_text + ")"])

func setup_layout():
	calculate_optimal_layout()
	configure_bundles_grid()
	
	get_viewport().size_changed.connect(_on_viewport_resized)

func calculate_optimal_layout():
	var viewport_size = get_viewport().size
	var available_width = viewport_size.x - 350
	
	var target_card_width = 260
	var min_spacing = 20
	var max_columns = 6
	
	var theoretical_columns = int(available_width / (target_card_width + min_spacing))
	var optimal_columns = clamp(theoretical_columns, 2, max_columns)
	
	var total_spacing = min_spacing * (optimal_columns - 1)
	var actual_card_width = (available_width - total_spacing) / optimal_columns
	
	layout_config = {
		"columns": optimal_columns,
		"card_width": max(220, actual_card_width), 
		"card_height": _calculate_card_height(actual_card_width),
		"spacing": min_spacing,
		"viewport_width": viewport_size.x,
		"viewport_height": viewport_size.y
	}

func _calculate_card_height(card_width: float) -> float:
	return card_width * 0.75

func configure_bundles_grid():
	if layout_config.is_empty():
		return
	
	bundles_grid.columns = layout_config.columns
	
	var spacing = layout_config.spacing
	bundles_grid.add_theme_constant_override("h_separation", spacing)
	bundles_grid.add_theme_constant_override("v_separation", spacing)
	
	bundles_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bundles_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

func _on_viewport_resized():
	call_deferred("recalculate_layout")

func recalculate_layout():
	calculate_optimal_layout()
	configure_bundles_grid()
	
	for card in bundle_card_instances:
		if card and is_instance_valid(card):
			_update_card_size(card)

func setup_dialog_system():
	dialog_timer = Timer.new()
	dialog_timer.one_shot = true
	dialog_timer.timeout.connect(_process_dialog_queue)
	add_child(dialog_timer)

func queue_dialog_sequence(dialogs: Array):
	current_dialog_queue = dialogs.duplicate()
	_process_dialog_queue()

func _process_dialog_queue():
	if current_dialog_queue.is_empty():
		dialog_timer.wait_time = 8.0
		dialog_timer.start()
		current_dialog_queue = [casual_dialogs[randi() % casual_dialogs.size()]]
		return
	
	var next_dialog = current_dialog_queue.pop_front()
	show_ai_dialog(next_dialog)
	
	dialog_timer.wait_time = 3.5
	dialog_timer.start()

func setup_ui():
	back_button.pressed.connect(_on_back_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	
	if OS.is_debug_build():
		debug_button.visible = true
		debug_button.pressed.connect(_on_debug_pressed)
	
	var buttons = [back_button, refresh_button, debug_button]
	for button in buttons:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.focus_entered.connect(_on_button_focus.bind(button))
		
func handle_lost_game_state():
	if accessed_from_game and not GameStateManager.has_saved_state():
		queue_dialog_sequence(["I'm sorry, but your game state seems to have been lost..."])
		accessed_from_game = false
		back_button.text = "BACK TO MENU"
		
		var timer = Timer.new()
		timer.wait_time = 3.0
		timer.one_shot = true
		timer.timeout.connect(func(): queue_dialog_sequence(["You'll need to start a new game from the main menu."]))
		add_child(timer)
		timer.start()

func setup_ai_character():
	if UnlockManagers:
		UnlockManagers.bundle_unlocked.connect(_on_bundle_unlocked)
		UnlockManagers.progress_updated.connect(_on_progress_updated)
	
	ai_avatar.visible = false
	
	robot_head_instance = robot_head_scene.instantiate()
	ai_avatar.get_parent().add_child(robot_head_instance)
	
	robot_head_instance.anchor_left = 0.5
	robot_head_instance.anchor_right = 0.5
	robot_head_instance.anchor_top = 0.3
	robot_head_instance.anchor_bottom = 0.5
	robot_head_instance.offset_left = -100
	robot_head_instance.offset_right = 100
	robot_head_instance.offset_top = -80
	robot_head_instance.offset_bottom = 40

func handle_scene_entrance():
	await get_tree().process_frame
	
	if TransitionManager and TransitionManager.current_overlay:
		if (TransitionManager.current_overlay.has_method("is_ready") and 
			TransitionManager.current_overlay.is_ready() and 
			TransitionManager.current_overlay.has_method("is_covering") and
			TransitionManager.current_overlay.is_covering()):
			
			await TransitionManager.current_overlay.fade_out(0.6)
		else:
			play_entrance_animation()
	else:
		play_entrance_animation()

func play_entrance_animation():
	modulate.a = 0.0
	scale = Vector2(0.95, 0.95)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4)

func load_shop_data():
	if not UnlockManagers:
		return
	
	update_stats_display()
	load_bundles()

func update_stats_display():
	var stats = UnlockManagers.get_unlock_stats()
	
	var percentage = "%.1f" % stats.completion_percentage
	stats_label.text = "Collection Progress: %d/%d bundles unlocked (%s%% complete)" % [
		stats.unlocked_bundles,
		stats.total_bundles, 
		percentage
	]

func load_bundles():
	for instance in bundle_card_instances:
		if is_instance_valid(instance):
			instance.queue_free()
	bundle_card_instances.clear()
	
	var bundles = UnlockManagers.get_all_bundles_info()
	
	for bundle_info in bundles:
		var bundle_card = create_bundle_card(bundle_info)
		bundles_grid.add_child(bundle_card)
		bundle_card_instances.append(bundle_card)
	
	selected_bundle_index = 0
	if gamepad_mode:
		update_bundle_selection()

func create_bundle_card(bundle_info: Dictionary) -> BundleCard:
	var bundle_card = bundle_card_scene.instantiate() as BundleCard
	
	bundle_card.setup_bundle(bundle_info)
	
	_update_card_size(bundle_card)
	
	bundle_card.mouse_filter = Control.MOUSE_FILTER_PASS
	
	if bundle_card.bundle_unlock_requested.connect(_on_bundle_unlock_requested) != OK:
		print("Error connecting bundle_unlock_requested")
	if bundle_card.bundle_hovered.connect(_on_bundle_hovered) != OK:
		print("Error connecting bundle_hovered")
	if bundle_card.bundle_unhovered.connect(_on_bundle_unhovered) != OK:
		print("Error connecting bundle_unhovered")
	
	print("Bundle card created and signals connected for: ", bundle_info.get("name", "Unknown"))
	
	return bundle_card

func _update_card_size(bundle_card: BundleCard):
	if layout_config.is_empty():
		return
	
	var card_width = layout_config.card_width
	var card_height = layout_config.card_height
	
	bundle_card.custom_minimum_size = Vector2(card_width, card_height)
	bundle_card.size = Vector2(card_width, card_height)

func show_ai_dialog(text: String):
	if not dialog_text:
		return

	if robot_head_instance:
		robot_head_instance.set_speaking(true)
		robot_head_instance.pulse_status_light()
		
		if status_light:
			status_light.color = Color(0.2, 0.8, 1.0, 1.0)
			var light_tween = create_tween()
			light_tween.set_loops(3)
			light_tween.tween_property(status_light, "modulate:a", 0.3, 0.4)
			light_tween.tween_property(status_light, "modulate:a", 1.0, 0.4)
	
	if typing_indicator:
		typing_indicator.visible = true
		var typing_tween = create_tween()
		typing_tween.set_loops(2)
		typing_tween.tween_property(typing_indicator, "modulate:a", 0.3, 0.3)
		typing_tween.tween_property(typing_indicator, "modulate:a", 1.0, 0.3)
		
		await get_tree().create_timer(0.8).timeout
		typing_indicator.visible = false
		
	dialog_text.text = text
	dialog_text.modulate.a = 0.0
	dialog_text.scale = Vector2(0.9, 0.9)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dialog_text, "modulate:a", 1.0, 0.3)
	tween.tween_property(dialog_text, "scale", Vector2(1.0, 1.0), 0.2)
	
	await tween.finished
	start_float_animation()

	await get_tree().create_timer(1.5).timeout
	if robot_head_instance:
		robot_head_instance.set_speaking(false)
	
	if status_light:
		status_light.color = Color(0.2, 0.8, 0.4, 0.8)

func start_float_animation():
	if not dialog_text:
		return
	
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(dialog_text, "position:y", dialog_text.position.y - 2, 1.5)
	float_tween.tween_property(dialog_text, "position:y", dialog_text.position.y + 2, 1.5)

func animate_ai_speaking():
	if not robot_head_instance:
		return
	
	robot_head_instance.set_speaking(true)
	robot_head_instance.pulse_status_light()
	
	await get_tree().create_timer(2.0).timeout
	robot_head_instance.set_speaking(false)

func _on_bundle_unlock_requested(bundle_id: String):
	if not UnlockManagers:
		return
	
	play_ui_sound("unlock")
	
	var unlocked_cards = UnlockManagers.unlock_bundle(bundle_id)
	if unlocked_cards.size() > 0:
		queue_dialog_sequence(["Excellent work! A new bundle awaits you."])
		await get_tree().create_timer(1.0).timeout
		load_shop_data()

func _on_bundle_hovered(bundle_info: Dictionary):
	if robot_head_instance:
		if bundle_info.can_unlock:
			robot_head_instance.set_mood("alert")
		elif bundle_info.unlocked:
			robot_head_instance.set_mood("happy")
		else:
			robot_head_instance.set_mood("normal")

func _get_hover_message(bundle_info: Dictionary) -> String:
	if bundle_info.unlocked:
		return "You already own the " + bundle_info.name + "!"
	elif bundle_info.can_unlock:
		return "Ah, the " + bundle_info.name + " is ready for you!"
	else:
		var progress_text = UnlockManagers.get_progress_text(bundle_info.id)
		return "The " + bundle_info.name + " awaits... " + progress_text

func _on_bundle_unhovered():
	pass

func _on_bundle_unlocked(bundle_id: String, cards: Array):
	var bundle_info = UnlockManagers.get_bundle_info(bundle_id)
	var message = "Congratulations! " + bundle_info.name + " is now available!"
	queue_dialog_sequence([message])
	
	if robot_head_instance:
		robot_head_instance.set_mood("happy")
		robot_head_instance.flash_neck_lights()
	
	if status_light:
		var celebration_tween = create_tween()
		celebration_tween.set_loops(5)
		celebration_tween.tween_property(status_light, "color", Color.GOLD, 0.2)
		celebration_tween.tween_property(status_light, "color", Color(0.2, 0.8, 0.4, 0.8), 0.2)
	
	load_shop_data()

func _on_progress_updated(bundle_id: String, current: int, required: int):
	if current == required - 1 and required > 1:
		var bundle_info = UnlockManagers.get_bundle_info(bundle_id)
		var encouragement = "You're almost ready for " + bundle_info.name + "!"
		queue_dialog_sequence([encouragement])

func _on_back_pressed():
	if is_transitioning:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")

	if accessed_from_game:
		queue_dialog_sequence(["Good luck in your battle!"])
		await get_tree().create_timer(0.8).timeout
		
		if GlobalMusicManager:
			GlobalMusicManager.stop_all_music(0.5)
		
		TransitionManager.fade_to_scene("res://scenes/Main.tscn", 0.8)
	else:
		if GlobalMusicManager:
			GlobalMusicManager.stop_challenge_music_for_menu(0.5)
		
		TransitionManager.fade_to_scene("res://scenes/MainMenu.tscn", 0.8)

func _on_refresh_pressed():
	play_ui_sound("button_click")
	load_shop_data()
	queue_dialog_sequence(["*refreshes inventory* Everything's up to date!"])

func _on_debug_pressed():
	if not UnlockManagers:
		return
	
	if debug_mode_unlock:
		var all_bundles = UnlockManagers.get_all_bundles_info()
		for bundle in all_bundles:
			if not bundle.unlocked:
				var bundle_info = UnlockManagers.bundles.get(bundle.id, {})
				var required = bundle_info.get("requirement_value", 0)
				UnlockManagers.bundle_progress[bundle.id] = required
				UnlockManagers.unlock_bundle(bundle.id, false)
		
		UnlockManagers.save_progress()
		
		load_shop_data()
		queue_dialog_sequence(["*winks* Everything's unlocked now!"])
		
		debug_button.text = "🗑️ RESET ALL"
		debug_mode_unlock = false
		
	else:
		UnlockManagers.reset_all_progress()
		
		load_shop_data()
		queue_dialog_sequence(["*serious* Back to basics. Prove yourself again."])
		
		debug_button.text = "🔓 UNLOCK ALL"
		debug_mode_unlock = true

func _on_button_hover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	
	if not button.mouse_exited.is_connected(_on_button_unhover):
		button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_button_focus(button: Button):
	_enter_mouse_mode()

func play_ui_sound(sound_type: String):
	match sound_type:
		"button_click":
			ui_player.stream = preload("res://audio/ui/button_click.wav")
			ui_player.play()
		"unlock":
			ui_player.stream = preload("res://audio/ui/button_click.wav")
			ui_player.pitch_scale = 1.2
			ui_player.play()
			ui_player.pitch_scale = 1.0

func play_hover_sound():
	hover_player.stream = preload("res://audio/ui/button_click.wav")
	hover_player.volume_db = -15.0
	hover_player.play()

func _handle_gamepad_input(event):
	if bundles_scroll_container.has_focus():
		if event.is_action_pressed("ui_right"):
			navigate_bundles(Vector2.RIGHT)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_left"):
			navigate_bundles(Vector2.LEFT)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_down"):
			navigate_bundles(Vector2.DOWN)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up"):
			navigate_bundles(Vector2.UP)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("game_select"):
			activate_selected_bundle()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") and not bundles_scroll_container.has_focus():
		if bundle_card_instances.size() > 0:
			bundles_scroll_container.grab_focus()
			get_viewport().set_input_as_handled()

func _input(event):
	if is_transitioning:
		return
	
	_detect_input_method(event)
	
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("game_back"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
		return
	
	if gamepad_mode:
		_handle_gamepad_input(event)
	
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("game_select"):
		if back_button.has_focus():
			_on_back_pressed()
			get_viewport().set_input_as_handled()
		elif refresh_button.has_focus():
			_on_refresh_pressed()
			get_viewport().set_input_as_handled()
		elif debug_button.has_focus() and debug_button.visible:
			_on_debug_pressed()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("game_restart"):
		_on_refresh_pressed()
		get_viewport().set_input_as_handled()
	
	elif gamepad_mode and bundles_scroll_container.has_focus():
		var scroll_amount = scroll_speed * get_process_delta_time()
		if Input.is_action_pressed("ui_page_down") or event.is_action_pressed("ui_page_down"):
			bundles_scroll_container.scroll_vertical += scroll_amount
			get_viewport().set_input_as_handled()
		elif Input.is_action_pressed("ui_page_up") or event.is_action_pressed("ui_page_up"):
			bundles_scroll_container.scroll_vertical -= scroll_amount
			get_viewport().set_input_as_handled()

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if dialog_timer:
			dialog_timer.stop()

		if GlobalMusicManager and GlobalMusicManager.is_challenge_music_playing():
			GlobalMusicManager.stop_all_music(0.3)
	elif what == NOTIFICATION_RESIZED:
		pass
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		if accessed_from_game:
			GameStateManager.clear_saved_state()
