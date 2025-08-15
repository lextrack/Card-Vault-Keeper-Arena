extends Control

@onready var stats_label = $MainContainer/HeaderContainer/StatsSection/StatsLabel
@onready var bundles_grid = $MainContainer/ContentContainer/BundlesPanel/BundlesScrollContainer/BundlesGrid
@onready var bundles_scroll_container = $MainContainer/ContentContainer/BundlesPanel/BundlesScrollContainer
@onready var ai_avatar = $MainContainer/ContentContainer/AIContainer/AIPanel/AIContent/AICharacterContainer/AIAvatar
@onready var dialog_text = $MainContainer/ContentContainer/AIContainer/AIPanel/AIContent/AIDialogContainer/DialogBubble/DialogBox/DialogText
@onready var dialog_bg = $MainContainer/ContentContainer/AIContainer/AIPanel/AIContent/AIDialogContainer/DialogBubble/DialogBox/DialogBG
@onready var status_light = $MainContainer/ContentContainer/AIContainer/AIPanel/AIContent/AIDialogContainer/DialogBubble/DialogBox/StatusLight
@onready var typing_indicator = $MainContainer/ContentContainer/AIContainer/AIPanel/AIContent/AIDialogContainer/DialogBubble/DialogBox/TypingIndicator
@onready var back_button = $MainContainer/HeaderContainer/StatsSection/ButtonsContainer/BackButton
@onready var refresh_button = $MainContainer/HeaderContainer/StatsSection/ButtonsContainer/RefreshButton
@onready var debug_button = $MainContainer/HeaderContainer/StatsSection/ButtonsContainer/DebugButton
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

var adaptive_columns: bool = true
var min_card_width: float = 320.0
var max_columns: int = 3

var dialog_timer: Timer
var current_dialog_queue: Array = []

var robot_current_mood: String = "normal"
var robot_speaking_timer: Timer
var dialog_duration_per_word: float = 0.15

var intro_dialogs = [
	"Welcome to my collection vault...",
	"I am the keeper of these powerful card bundles.",
	"Complete the challenges and the cards contained in these bundles will be yours."
]

var casual_dialogs = [
	"Browse at your leisure...",
	"Some challenges are harder than others, but the rewards match.",
	"Every great warrior needs the right tools...",
	"Shield cards have saved more battles than most realize.",
	"I hope it doesn't take you too long to get your cards back.",
	"When we duel, I'll use some of these very cards against you...",
	"The cards are watching your progress with interest...",
	"I've seen warriors fall because they ignored defensive cards.",
	"Every card in my vault has proven its worth in battle.",
	"The ancient cards whisper secrets of victory...",
	"Power calls to those who dare to earn it.",
	"Power is fleeting, but mastery lasts forever.",
	"Did you know that I assign your life, mana, and cards in your hand?",
	"Unlock more bundles so we have more cards to play together.",
	"A single card can turn the tide of battle... if you know when to play it. Make sure to check you mana.",
	"Besides dueling you and keeping these bundles, I also keep track of your actions in the statistics section."
]

var mysterious_dialogs = [
	"Something stirs in the vault...",
	"The cards sense your presence...",
	"Ancient powers await the worthy...",
	"I sense potential in you...",
	"The path to mastery is never easy...",
	"Destiny favors the prepared mind...",
	"Knowledge is the sharpest blade...",
	"Victory belongs to those who understand...",
	"Looking through the game files, most of the design was planned and done with HTML and CSS, what a curious decision."
]

func _ready():
	accessed_from_game = GameStateManager.has_saved_state()
	
	setup_ui()
	setup_ai_character()
	setup_dialog_system()
	setup_gamepad_navigation()
	setup_challenge_music()
	
	get_viewport().size_changed.connect(_on_viewport_resized)

	
	if accessed_from_game:
		back_button.text = "BACK TO GAME"
		var game_age = GameStateManager.get_save_age_seconds()
		if game_age >= 0 and game_age < 60:
			queue_dialog_sequence(["Your battle awaits... Take your time browsing."])
		else:
			queue_dialog_sequence(["Ahh, you return to my vault..."])
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
	
	call_deferred("setup_responsive_layout")

func _process(delta):
	if input_cooldown > 0:
		input_cooldown -= delta

func _on_viewport_resized():
	if adaptive_columns:
		call_deferred("setup_responsive_layout")

func setup_responsive_layout():
	if not bundles_grid:
		return
	
	var viewport_size = get_viewport().get_visible_rect().size
	var panel_width = bundles_scroll_container.size.x - 40
	
	var optimal_columns = max(1, int(panel_width / min_card_width))
	optimal_columns = min(optimal_columns, max_columns)
	
	if bundles_grid.columns != optimal_columns:
		bundles_grid.columns = optimal_columns
	
	var h_separation = 15
	var v_separation = 12
	
	if optimal_columns == 1:
		h_separation = 0
		v_separation = 20
	elif optimal_columns >= 3:
		h_separation = 10
		v_separation = 10
	
	bundles_grid.add_theme_constant_override("h_separation", h_separation)
	bundles_grid.add_theme_constant_override("v_separation", v_separation)

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
	
	selected_bundle_index = clamp(selected_bundle_index, 0, bundle_card_instances.size() - 1)
	
	for i in range(bundle_card_instances.size()):
		var bundle_card = bundle_card_instances[i]
		if is_instance_valid(bundle_card):
			bundle_card.modulate = Color.WHITE
			bundle_card.z_index = 0
			bundle_card.scale = Vector2(1.0, 1.0)
	
	var selected_bundle = bundle_card_instances[selected_bundle_index]
	if is_instance_valid(selected_bundle):
		selected_bundle.modulate = Color(1.05, 1.05, 1.0, 1.0)
		selected_bundle.z_index = 10
		selected_bundle.scale = Vector2(1.02, 1.02)
		
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
	await get_tree().process_frame
	
	var bundle_global_rect = selected_bundle.get_global_rect()
	var scroll_container_global_rect = bundles_scroll_container.get_global_rect()
	
	var bundle_top_relative = bundle_global_rect.position.y - scroll_container_global_rect.position.y
	var bundle_bottom_relative = bundle_top_relative + bundle_global_rect.size.y
	
	var visible_top = bundles_scroll_container.scroll_vertical
	var visible_bottom = visible_top + bundles_scroll_container.size.y
	
	var target_scroll = bundles_scroll_container.scroll_vertical
	var margin = 60
	
	if bundle_top_relative + visible_top < visible_top + margin:
		target_scroll = max(0, bundle_top_relative + visible_top - margin)
	elif bundle_bottom_relative + visible_top > visible_bottom - margin:
		target_scroll = bundle_bottom_relative + visible_top - bundles_scroll_container.size.y + margin
	
	if abs(target_scroll - bundles_scroll_container.scroll_vertical) > 5:
		var tween = create_tween()
		tween.tween_property(bundles_scroll_container, "scroll_vertical", target_scroll, 0.25)
		await tween.finished

func navigate_bundles(direction: Vector2) -> bool:
	if bundle_card_instances.size() == 0 or input_cooldown > 0:
		return false
	
	input_cooldown = input_cooldown_time
	
	var columns = bundles_grid.columns
	var total_items = bundle_card_instances.size()
	var current_row = selected_bundle_index / columns
	var current_col = selected_bundle_index % columns
	var total_rows = (total_items - 1) / columns
	
	var new_index = selected_bundle_index
	
	match direction:
		Vector2.RIGHT:
			new_index = selected_bundle_index + 1
			if new_index >= total_items:
				new_index = 0
		
		Vector2.LEFT:
			new_index = selected_bundle_index - 1
			if new_index < 0:
				new_index = total_items - 1
		
		Vector2.DOWN:
			var target_row = current_row + 1
			if target_row <= total_rows:
				new_index = target_row * columns + current_col
				if new_index >= total_items:
					new_index = total_items - 1
			else:
				new_index = current_col
				if new_index >= total_items:
					new_index = 0
		
		Vector2.UP:
			var target_row = current_row - 1
			if target_row >= 0:
				new_index = target_row * columns + current_col
			else:
				var last_row_start = total_rows * columns
				new_index = last_row_start + current_col
				if new_index >= total_items:
					new_index = total_items - 1
	
	if new_index != selected_bundle_index and new_index >= 0 and new_index < total_items:
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
		queue_dialog_sequence(["The path is not yet clear..."])

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
		var dialog_pool = casual_dialogs + mysterious_dialogs
		current_dialog_queue = [dialog_pool[randi() % dialog_pool.size()]]
		return
	
	var next_dialog = current_dialog_queue.pop_front()
	show_ai_dialog(next_dialog)
	
	var word_count = next_dialog.split(" ").size()
	var base_time = max(3.0, word_count * 0.2)
	dialog_timer.wait_time = base_time
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
		queue_dialog_sequence(["The threads of your battle have been severed..."])
		accessed_from_game = false
		back_button.text = "BACK TO MENU"
		
		var timer = Timer.new()
		timer.wait_time = 3.0
		timer.one_shot = true
		timer.timeout.connect(func(): queue_dialog_sequence(["A new path must be forged from the beginning."]))
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
	
	setup_robot_speaking_timer()
	
func setup_robot_speaking_timer():
	robot_speaking_timer = Timer.new()
	robot_speaking_timer.one_shot = true
	robot_speaking_timer.timeout.connect(_on_robot_speaking_finished)
	add_child(robot_speaking_timer)

func _on_robot_speaking_finished():
	if robot_head_instance:
		robot_head_instance.set_speaking(false)
		robot_head_instance.set_mood(robot_current_mood)

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
	scale = Vector2(0.90, 0.90)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 5.4)

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
	
	if not UnlockManagers:
		print("ERROR: UnlockManagers is null in load_bundles!")
		return
	
	if not bundles_grid:
		print("ERROR: bundles_grid is null! Path: ", get_path())
		return
	
	var bundles = UnlockManagers.get_all_bundles_info()
	print("Found ", bundles.size(), " bundles to load")
	
	for i in range(bundles.size()):
		var bundle_info = bundles[i]
		print("Creating bundle card for: ", bundle_info.get("name", "Unknown"))
		var bundle_card = create_bundle_card(bundle_info)
		bundles_grid.add_child(bundle_card)
		bundle_card_instances.append(bundle_card)
	
	call_deferred("force_grid_layout")
	
	selected_bundle_index = 0
	if gamepad_mode:
		update_bundle_selection()

func force_grid_layout():
	if not bundles_grid:
		return
	
	await get_tree().process_frame
	
	setup_responsive_layout()
	
	bundles_grid.queue_sort()
	
	var available_width = bundles_scroll_container.size.x - 40
	var columns = bundles_grid.columns
	var separation = bundles_grid.get_theme_constant("h_separation")
	var card_width = (available_width - (separation * (columns - 1))) / columns
	
	card_width = max(card_width, min_card_width)
	
	for child in bundles_grid.get_children():
		if child is BundleCard:
			child.custom_minimum_size = Vector2(card_width, 360)
			child.size = Vector2(card_width, 360)
	
	await get_tree().process_frame
	bundles_grid.queue_sort()

func create_bundle_card(bundle_info: Dictionary) -> BundleCard:
	var bundle_card = bundle_card_scene.instantiate() as BundleCard
	
	bundle_card.setup_bundle(bundle_info)
	bundle_card.mouse_filter = Control.MOUSE_FILTER_PASS
	
	if bundle_card.bundle_unlock_requested.connect(_on_bundle_unlock_requested) != OK:
		print("Error connecting bundle_unlock_requested")
	if bundle_card.bundle_hovered.connect(_on_bundle_hovered) != OK:
		print("Error connecting bundle_hovered")
	if bundle_card.bundle_unhovered.connect(_on_bundle_unhovered) != OK:
		print("Error connecting bundle_unhovered")
	
	print("Bundle card created with size: ", bundle_card.size, " for: ", bundle_info.get("name", "Unknown"))
	
	return bundle_card

func show_ai_dialog(text: String):
	if not dialog_text:
		return

	if robot_head_instance:
		robot_head_instance.set_speaking(true)
		robot_head_instance.pulse_status_light()
		
		var word_count = text.split(" ").size()
		var speaking_duration = max(2.0, word_count * dialog_duration_per_word)
		robot_speaking_timer.wait_time = speaking_duration
		robot_speaking_timer.start()
		
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
		var new_mood = "normal"
		
		if bundle_info.can_unlock:
			new_mood = "alert"
			robot_head_instance.dramatic_reaction("excitement")
		elif bundle_info.unlocked:
			new_mood = "happy"
		else:
			new_mood = "normal"
		
		if not robot_speaking_timer.time_left > 0:
			robot_head_instance.set_mood(new_mood)
		
		robot_current_mood = new_mood

func _get_mysterious_hover_message(bundle_info: Dictionary) -> String:
	if bundle_info.unlocked:
		var positive_messages = [
			"This power serves you well...",
			"A worthy addition to your arsenal.",
			"These cards remember their master."
		]
		return positive_messages[randi() % positive_messages.size()]
	elif bundle_info.can_unlock:
		var ready_messages = [
			"The moment approaches...",
			"Power calls to you...",
			"Your efforts have borne fruit.",
			"The vault recognizes your worth."
		]
		return ready_messages[randi() % ready_messages.size()]
	else:
		var locked_messages = [
			"Patience, young warrior...",
			"The path demands more...",
			"Not yet...",
			"Prove your worth first.",
			"These secrets are well guarded."
		]
		return locked_messages[randi() % locked_messages.size()]

func _on_bundle_unhovered():
	if robot_head_instance:
		if not robot_speaking_timer.time_left > 0:
			robot_head_instance.set_mood("normal")
		robot_current_mood = "normal"

func _on_bundle_unlocked(bundle_id: String, cards: Array):
	var bundle_info = UnlockManagers.get_bundle_info(bundle_id)
	var celebration_messages = [
		"The vault yields its secrets!",
		"Power is yours to command!",
		"Another mystery unveiled...",
		"Your destiny unfolds..."
	]
	queue_dialog_sequence([celebration_messages[randi() % celebration_messages.size()]])
	
	if robot_head_instance:
		robot_head_instance.dramatic_reaction("excitement")
		robot_head_instance.set_mood("happy")
		robot_head_instance.flash_neck_lights()
		robot_current_mood = "happy"
		
		var happiness_timer = Timer.new()
		happiness_timer.wait_time = 5.0
		happiness_timer.one_shot = true
		happiness_timer.timeout.connect(func():
			robot_current_mood = "normal"
			if not robot_speaking_timer.time_left > 0:
				robot_head_instance.set_mood("normal")
		)
		add_child(happiness_timer)
		happiness_timer.start()

	if status_light:
		var celebration_tween = create_tween()
		celebration_tween.set_loops(8)
		celebration_tween.tween_property(status_light, "color", Color.GOLD, 0.2)
		celebration_tween.tween_property(status_light, "color", Color(0.2, 0.8, 0.4, 0.8), 0.2)
	
	load_shop_data()

func _on_progress_updated(bundle_id: String, current: int, required: int):
	if current == required - 1 and required > 1:
		if randf() < 0.3:
			var subtle_encouragement = [
				"Something stirs in the depths...",
				"The vault trembles with anticipation...",
				"Power grows restless..."
			]
			queue_dialog_sequence([subtle_encouragement[randi() % subtle_encouragement.size()]])

func _on_back_pressed():
	if is_transitioning:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")

	if accessed_from_game:
		queue_dialog_sequence(["May fortune favor your battles..."])
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
	queue_dialog_sequence(["The vault's knowledge refreshes itself..."])

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
		queue_dialog_sequence(["*The vault bends to your will* All secrets revealed."])
		
		debug_button.text = "🗑️ RESET ALL"
		debug_mode_unlock = false
		
	else:
		UnlockManagers.reset_all_progress()
		
		load_shop_data()
		queue_dialog_sequence(["*The vault seals itself once more* Prove yourself again, warrior."])
		
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
		var handled = false
		
		if event.is_action_pressed("ui_right"):
			handled = navigate_bundles(Vector2.RIGHT)
		elif event.is_action_pressed("ui_left"):
			handled = navigate_bundles(Vector2.LEFT)
		elif event.is_action_pressed("ui_down"):
			handled = navigate_bundles(Vector2.DOWN)
		elif event.is_action_pressed("ui_up"):
			handled = navigate_bundles(Vector2.UP)
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("game_select"):
			activate_selected_bundle()
			handled = true
		
		if handled:
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
		if robot_speaking_timer:
			robot_speaking_timer.stop()

		if GlobalMusicManager and GlobalMusicManager.is_challenge_music_playing():
			GlobalMusicManager.stop_all_music(0.3)
	elif what == NOTIFICATION_RESIZED:
		pass
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		if accessed_from_game:
			GameStateManager.clear_saved_state()
