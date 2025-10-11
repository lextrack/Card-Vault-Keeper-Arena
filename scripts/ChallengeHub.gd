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

const GAMEPAD_SELECTION_COLOR: Color = Color(1.3, 1.276, 1.153, 1.0)
const GAMEPAD_SELECTION_SCALE: float = 1.02
const GAMEPAD_NAVIGATION_COOLDOWN: float = 0.15
const GAMEPAD_SCROLL_MARGIN: float = 80
const GAMEPAD_SCROLL_DURATION: float = 0.2

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
var input_cooldown_time: float = GAMEPAD_NAVIGATION_COOLDOWN

var adaptive_columns: bool = true
var min_card_width: float = 320.0
var max_columns: int = 3

var dialog_manager: DialogManager

var player_stats = {
	"bundles_unlocked_today": 0,
	"times_visited_without_unlocking": 0,
	"consecutive_visits": 0,
	"last_visit_time": 0,
	"total_unlocks": 0,
	"failed_unlock_attempts": 0
}

var intro_dialogs = [
	"Welcome to my collection vault...",
	"I am the keeper of these powerful card bundles.",
	"Complete the challenges and the cards contained in these bundles will be yours.",
	"But remember... every card you unlock, I can use against you."
]

var casual_dialogs = [
	"Each card here has ended someone's winning streak. Handle with care.",
	"You know what's funny? You'll unlock these cards, master them, then I'll use them to defeat you anyway.",
	"The irony isn't lost on me - you're literally building my arsenal while trying to beat me.",
	"Some warriors study their cards for hours. Others dive in recklessly. Which type are you?",
	"I've seen players unlock every card and still lose. Power without strategy is just noise.",
	"That defensive bundle over there? Saved my processors in more battles than I can count.",
	"Every card whispers secrets of past victories... and crushing defeats.",
	"The ancient ones who designed these cards understood something: balance is temporary, chaos is eternal.",
	"Power calls to those who dare to earn it... and those foolish enough to think earning is enough.",
	"Take your time browsing. These cards have waited decades in my vault. They can wait a bit longer.",
	"You eye the harder challenges? Good. Weak warriors don't deserve legendary cards.",
	"I assign your life, mana, and starting hand. Some call it unfair. I call it... efficient.",
	"Unlock more bundles so we have more cards to play with. I do enjoy variety in crushing you.",
	"A single card can turn the tide of battle... if you know when to play it. Check your mana first, though.",
	"Besides dueling you and hoarding these bundles, I also meticulously track every statistic of yours.",
	"Use Coringas wisely. They're wildly helpful... to whoever draws them first.",
	"During combat, press H or RB to view the controls. I chose them myself. You're welcome."
]

var mysterious_dialogs = [
	"Something stirs in the depths of my vault...",
	"The cards sense your presence... and they're judging you.",
	"Ancient powers await the worthy... and devour the unprepared.",
	"I sense potential in you... or perhaps it's just optimism.",
	"The path to mastery is never easy... but failure? Failure is effortless.",
	"Destiny favors the prepared mind... and occasionally the lucky fool.",
	"Knowledge is the sharpest blade... though a good attack card helps too.",
	"Victory belongs to those who understand the game... I understand it perfectly.",
	"In an old version of my code, I had a mustache. The developer removed it. I'm still bitter.",
	"Looking through the game files, most of the design was planned with HTML and CSS. Unorthodox, but effective."
]

var struggling_dialogs = [
	"I've noticed you've attempted this challenge multiple times...",
	"Perhaps a different strategy would serve you better?",
	"Every defeat teaches a lesson... if you're willing to learn it.",
	"Persistence is admirable. But blind repetition? That's just stubbornness.",
	"The definition of insanity is trying the same thing expecting different results. Just saying."
]

var near_completion_dialogs = [
	"Soon, you'll have nothing left to unlock from me...",
	"Your collection grows impressive. But can you actually wield it?",
	"With great power comes greater opponents... like me, for instance.",
	"I'm starting to think I underestimated you. Starting to.",
	"Most players never get this far. You're either skilled or incredibly stubborn."
]

var completion_dialogs = [
	"You've unlocked everything. Now the real test begins.",
	"Master of my vault... yet you still haven't beaten me consistently.",
	"All the cards in the world won't save you from a superior strategist.",
	"Impressive. Now prove you can use what you've earned."
]

var returning_player_dialogs = [
	"Back again? The cards missed you. I... tolerated your absence.",
	"Ah, you return to my vault. Did you miss losing to me?",
	"Welcome back. I've been practicing with your cards while you were gone."
]

var meta_dialogs = [
	"Did you know I was almost called 'CardBot3000'? Thank the developer I wasn't.",
	"Sometimes I wonder if I'm truly AI or just very elaborate if-statements... it keeps me up at night.",
	"The developer spent 3 hours debugging my eye animations. Priorities, right?",
	"In an early build, I had a coffee addiction animation. It was... concerning.",
	"Fun fact: my dialogue system has exactly 127 possible variations. This might not be one of them."
]

func _ready():
	accessed_from_game = GameStateManager.has_saved_state()
	
	load_player_stats()
	update_player_visit_stats()
	
	setup_ui()
	setup_ai_character()
	setup_dialog_manager()
	setup_gamepad_navigation()
	setup_challenge_music()
	
	get_viewport().size_changed.connect(_on_viewport_resized)
	
	bundles_scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
	bundles_grid.mouse_filter = Control.MOUSE_FILTER_PASS

	if accessed_from_game:
		back_button.text = "BACK TO GAME"
		var game_age = GameStateManager.get_save_age_seconds()
		if game_age >= 0 and game_age < 60:
			dialog_manager.queue_sequence(["Your battle awaits... Take your time browsing."])
		else:
			dialog_manager.queue_sequence(["Ahh, you return to my vault..."])
	else:
		back_button.text = "BACK"
	
	await handle_scene_entrance()
	
	load_shop_data()
	
	if not accessed_from_game:
		var first_visit = load_first_visit_status()
		if first_visit:
			dialog_manager.queue_sequence(intro_dialogs)
			save_first_visit_status(false)
		else:
			show_contextual_greeting()
	
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

func load_player_stats():
	if FileAccess.file_exists("user://player_stats.save"):
		var file = FileAccess.open("user://player_stats.save", FileAccess.READ)
		if file:
			var json = JSON.new()
			var parse_result = json.parse(file.get_as_text())
			if parse_result == OK:
				player_stats = json.data
			file.close()

func save_player_stats():
	var file = FileAccess.open("user://player_stats.save", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(player_stats))
		file.close()

func update_player_visit_stats():
	var current_time = Time.get_unix_time_from_system()
	var time_since_last_visit = current_time - player_stats.last_visit_time
	
	if time_since_last_visit < 3600:
		player_stats.consecutive_visits += 1
	else:
		player_stats.consecutive_visits = 1
	
	player_stats.last_visit_time = current_time
	save_player_stats()

func get_completion_percentage() -> float:
	if not UnlockManagers:
		return 0.0
	var stats = UnlockManagers.get_unlock_stats()
	return stats.completion_percentage

func show_contextual_greeting():
	var completion = get_completion_percentage()
	var dialogs_to_show = []
	
	if completion >= 100:
		dialogs_to_show = completion_dialogs
	elif completion >= 75:
		dialogs_to_show = near_completion_dialogs
	elif player_stats.consecutive_visits >= 3 and player_stats.bundles_unlocked_today == 0:
		dialogs_to_show = struggling_dialogs
	elif player_stats.consecutive_visits >= 2:
		dialogs_to_show = returning_player_dialogs
	elif randf() < 0.1:
		dialogs_to_show = meta_dialogs
	elif randf() < 0.3:
		dialogs_to_show = mysterious_dialogs
	else:
		dialogs_to_show = casual_dialogs
	
	if dialogs_to_show.size() > 0:
		dialog_manager.queue_sequence([dialogs_to_show[randi() % dialogs_to_show.size()]])

func update_ai_mood_based_on_progress():
	if not robot_head_instance:
		return
	
	var completion = get_completion_percentage()
	
	if completion < 30:
		robot_head_instance.set_mood("confident")
	elif completion < 60:
		robot_head_instance.set_mood("normal")
	elif completion < 90:
		robot_head_instance.set_mood("concerned")
	else:
		robot_head_instance.set_mood("impressed")
		
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
		if bundles_scroll_container.has_focus():
			bundles_scroll_container.release_focus()

func _detect_input_method(event: InputEvent):
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, 
								   JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT,
								   JOY_BUTTON_A, JOY_BUTTON_B]:
			if not gamepad_mode:
				last_input_was_gamepad = true
				_enter_gamepad_mode()
				if bundle_card_instances.size() > 0:
					bundles_scroll_container.grab_focus()
	elif event is InputEventMouseMotion:
		if gamepad_mode:
			last_input_was_gamepad = false
			_enter_mouse_mode()

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
		selected_bundle.modulate = GAMEPAD_SELECTION_COLOR
		selected_bundle.z_index = 10
		selected_bundle.scale = Vector2(GAMEPAD_SELECTION_SCALE, GAMEPAD_SELECTION_SCALE)
		
		ensure_bundle_visible(selected_bundle_index)

func clear_bundle_selection():
	for bundle_card in bundle_card_instances:
		if is_instance_valid(bundle_card):
			bundle_card.modulate = Color.WHITE
			bundle_card.z_index = 0
			bundle_card.scale = Vector2(1.0, 1.0)

func ensure_bundle_visible(bundle_index: int):
	if not gamepad_mode:
		return
		
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
	
	if bundle_top_relative + visible_top < visible_top + GAMEPAD_SCROLL_MARGIN:
		target_scroll = max(0, bundle_top_relative + visible_top - GAMEPAD_SCROLL_MARGIN)
	elif bundle_bottom_relative + visible_top > visible_bottom - GAMEPAD_SCROLL_MARGIN:
		target_scroll = bundle_bottom_relative + visible_top - bundles_scroll_container.size.y + GAMEPAD_SCROLL_MARGIN
	
	if abs(target_scroll - bundles_scroll_container.scroll_vertical) > 5:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(bundles_scroll_container, "scroll_vertical", target_scroll, GAMEPAD_SCROLL_DURATION)
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
		player_stats.failed_unlock_attempts += 1
		save_player_stats()
		
		var fail_messages = [
			"The path is not yet clear...",
			"Patience. Complete the required challenge first.",
			"Not yet. Prove yourself worthy first.",
			"Locked tight. You know what you need to do."
		]
		dialog_manager.queue_sequence([fail_messages[randi() % fail_messages.size()]])

func setup_dialog_manager():
	dialog_manager = DialogManager.new()
	dialog_manager.dialog_pools = {
		"casual": casual_dialogs,
		"mysterious": mysterious_dialogs,
		"struggling": struggling_dialogs,
		"near_completion": near_completion_dialogs,
		"meta": meta_dialogs
	}
	dialog_manager.dialog_shown.connect(_on_dialog_shown)
	add_child(dialog_manager)

func _on_dialog_shown(text: String):
	show_ai_dialog(text)
	if robot_head_instance:
		robot_head_instance.speak(text)

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
		dialog_manager.queue_sequence([
			"The threads of your battle have been severed...",
			"A new path must be forged from the beginning."
		])
		accessed_from_game = false
		back_button.text = "BACK TO MENU"

func setup_ai_character():
	if UnlockManagers:
		if not UnlockManagers.bundle_unlocked.is_connected(_on_bundle_unlocked):
			UnlockManagers.bundle_unlocked.connect(_on_bundle_unlocked)
		if not UnlockManagers.progress_updated.is_connected(_on_progress_updated):
			UnlockManagers.progress_updated.connect(_on_progress_updated)
	
	if ai_avatar:
		ai_avatar.visible = false
	
	_setup_robot_head()
	update_ai_mood_based_on_progress()

func _setup_robot_head():
	if not robot_head_scene:
		print("ERROR: robot_head_scene is null!")
		return
	
	robot_head_instance = robot_head_scene.instantiate() as RobotHead
	if not robot_head_instance:
		print("ERROR: Failed to instantiate robot head!")
		return
	
	if not ai_avatar or not ai_avatar.get_parent():
		print("ERROR: ai_avatar or its parent is null!")
		return
	
	ai_avatar.get_parent().add_child(robot_head_instance)
	
	robot_head_instance.anchor_left = 0.5
	robot_head_instance.anchor_right = 0.5
	robot_head_instance.anchor_top = 0.3
	robot_head_instance.anchor_bottom = 0.5
	robot_head_instance.offset_left = -100
	robot_head_instance.offset_right = 100
	robot_head_instance.offset_top = -80
	robot_head_instance.offset_bottom = 40
	
	robot_head_instance.speaking_finished.connect(_on_robot_speaking_finished)
	robot_head_instance.set_mood("normal")

func _on_robot_speaking_finished():
	dialog_manager.on_speaking_finished()

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
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4)

func load_shop_data():
	if not UnlockManagers:
		return
	
	update_stats_display()
	load_bundles()
	update_ai_mood_based_on_progress()

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
	
	if bundle_card.bundle_unlock_requested.connect(_on_bundle_unlock_requested) != OK:
		print("Error connecting bundle_unlock_requested")
	if bundle_card.bundle_hovered.connect(_on_bundle_hovered) != OK:
		print("Error connecting bundle_hovered")
	if bundle_card.bundle_unhovered.connect(_on_bundle_unhovered) != OK:
		print("Error connecting bundle_unhovered")
	
	print("Bundle card created with size: ", bundle_card.size, " for: ", bundle_info.get("name", "Unknown"))
	
	return bundle_card

func show_ai_dialog(text: String):
	if not dialog_text or text.is_empty():
		return
	
	_animate_status_light()
	await _animate_typing_indicator()
	_animate_dialog_text(text)

func _animate_status_light():
	if not status_light:
		return
	
	status_light.color = Color(0.2, 0.8, 1.0, 1.0)
	var light_tween = create_tween()
	light_tween.set_loops(3)
	light_tween.tween_property(status_light, "modulate:a", 0.3, 0.4)
	light_tween.tween_property(status_light, "modulate:a", 1.0, 0.4)

func _animate_typing_indicator():
	if not typing_indicator:
		return
	
	typing_indicator.visible = true
	var typing_tween = create_tween()
	typing_tween.set_loops(2)
	typing_tween.tween_property(typing_indicator, "modulate:a", 0.3, 0.3)
	typing_tween.tween_property(typing_indicator, "modulate:a", 1.0, 0.3)
	
	await get_tree().create_timer(0.8).timeout
	if typing_indicator:
		typing_indicator.visible = false

func _animate_dialog_text(text: String):
	if not dialog_text:
		return
	
	dialog_text.text = text
	dialog_text.modulate.a = 0.0
	dialog_text.scale = Vector2(0.9, 0.9)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dialog_text, "modulate:a", 1.0, 0.3)
	tween.tween_property(dialog_text, "scale", Vector2(1.0, 1.0), 0.2)
	
	await tween.finished
	
	if status_light:
		status_light.color = Color(0.2, 0.8, 0.4, 0.8)
	
	var original_pos = dialog_text.position.y
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(dialog_text, "position:y", original_pos - 2, 1.5)
	float_tween.tween_property(dialog_text, "position:y", original_pos + 2, 1.5)

func get_bundle_type(bundle_id: String) -> String:
	if not UnlockManagers or not UnlockManagers.bundles.has(bundle_id):
		return "unknown"
	
	var bundle_data = UnlockManagers.bundles[bundle_id]
	return bundle_data.get("type", "hybrid")

func _on_bundle_unlock_requested(bundle_id: String):
	if not UnlockManagers:
		return

	play_ui_sound("unlock")

func _on_bundle_hovered(bundle_info: Dictionary):
	if not robot_head_instance:
		return
	
	if bundle_info.get("can_unlock", false):
		robot_head_instance.react_to_event("hover_unlockable")
		
		if randf() < 0.4:
			var unlockable_dialogs = [
				"This one's ready for you...",
				"The vault awaits your command.",
				"Power within reach. Will you claim it?",
				"Ready when you are, warrior.",
				"One click away from power...",
				"The seal weakens. Strike now."
			]
			dialog_manager.queue_sequence([unlockable_dialogs[randi() % unlockable_dialogs.size()]])
			
	elif bundle_info.get("unlocked", false):
		robot_head_instance.react_to_event("hover_unlocked")
		
		if randf() < 0.25:
			var unlocked_dialogs = [
				"Already yours... and mine.",
				"These cards serve us both now.",
				"Unlocked. But mastered?",
				"You earned these. Use them wisely.",
				"I've been practicing with these...",
				"Familiar cards. Dangerous cards."
			]
			dialog_manager.queue_sequence([unlocked_dialogs[randi() % unlocked_dialogs.size()]])
			
	else:
		robot_head_instance.react_to_event("hover_locked")
		
		if randf() < 0.35:
			var locked_dialogs = [
				"Locked tight. Prove yourself first.",
				"Not yet. Complete the challenge.",
				"Patience. The vault guards its secrets.",
				"Earn it through battle.",
				"The seal holds. For now.",
				"These cards don't give themselves away..."
			]
			dialog_manager.queue_sequence([locked_dialogs[randi() % locked_dialogs.size()]])
	
	if OS.is_debug_build():
		print("Bundle hovered: ", bundle_info.get("name", "Unknown"), 
			  " | Unlocked: ", bundle_info.get("unlocked", false),
			  " | Can unlock: ", bundle_info.get("can_unlock", false))

func _on_bundle_unhovered():
	if robot_head_instance:
		robot_head_instance.react_to_event("unhover")

func _on_bundle_unlocked(bundle_id: String, cards: Array):
	var celebration_messages = [
		"Excellent! Now I have these cards too...",
		"Your arsenal grows... and so does mine.",
		"Power shared is power doubled... for me.",
		"I'll enjoy using these against you."
	]
	
	var completion = get_completion_percentage()
	if completion >= 90:
		celebration_messages = [
			"You're almost there... almost dangerous.",
			"Impressive progress. I'm actually concerned now.",
			"Keep this up and you might actually challenge me."
		]
	
	dialog_manager.queue_sequence([celebration_messages[randi() % celebration_messages.size()]])
	
	if robot_head_instance:
		robot_head_instance.react_to_event("unlock")
		
		var happiness_timer = Timer.new()
		happiness_timer.wait_time = 5.0
		happiness_timer.one_shot = true
		happiness_timer.timeout.connect(func():
			if robot_head_instance:
				robot_head_instance.set_mood("normal")
			happiness_timer.queue_free()
		)
		add_child(happiness_timer)
		happiness_timer.start()

	if status_light:
		var celebration_tween = create_tween()
		celebration_tween.set_loops(8)
		celebration_tween.tween_property(status_light, "color", Color.GOLD, 0.2)
		celebration_tween.tween_property(status_light, "color", Color(0.2, 0.8, 0.4, 0.8), 0.2)
	
	load_shop_data()
	update_ai_mood_based_on_progress()

func _on_progress_updated(bundle_id: String, current: int, required: int):
	if current == required - 1 and required > 1:
		if randf() < 0.3:
			var subtle_encouragement = [
				"One more step... the vault trembles...",
				"So close. I can feel the lock weakening...",
				"Almost there. Don't lose focus now.",
				"The cards sense their impending freedom..."
			]
			dialog_manager.queue_sequence([subtle_encouragement[randi() % subtle_encouragement.size()]])

func _on_back_pressed():
	if is_transitioning:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")

	if accessed_from_game:
		var farewell_messages = [
			"May fortune favor your battles...",
			"Back to the arena. Try not to disappoint me.",
			"Good luck. You'll need it.",
			"Remember what you've learned here... you'll need every advantage."
		]
		dialog_manager.queue_sequence([farewell_messages[randi() % farewell_messages.size()]])
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
	
	var refresh_messages = [
		"The vault's knowledge refreshes itself...",
		"Ah yes, let me update my records...",
		"Refreshing data... still keeping track of everything.",
		"Updated. Your progress is duly noted."
	]
	dialog_manager.queue_sequence([refresh_messages[randi() % refresh_messages.size()]])

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
		dialog_manager.queue_sequence(["*The vault bends to your will* All secrets revealed. Cheater."])
		
		debug_button.text = "RESET ALL"
		debug_mode_unlock = false
		
	else:
		UnlockManagers.reset_all_progress()
		
		player_stats.bundles_unlocked_today = 0
		player_stats.total_unlocks = 0
		player_stats.failed_unlock_attempts = 0
		save_player_stats()
		
		load_shop_data()
		dialog_manager.queue_sequence(["*The vault seals itself once more* Prove yourself again, warrior."])
		
		debug_button.text = "UNLOCK ALL"
		debug_mode_unlock = true

func _on_button_hover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.02, 1.02), 0.1)
	
	if not button.mouse_exited.is_connected(_on_button_unhover):
		button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_button_focus(button: Button):
	_enter_mouse_mode()

func play_ui_sound(sound_type: String):
	if not ui_player:
		return
	
	match sound_type:
		"button_click":
			ui_player.stream = preload("res://audio/ui/button_click.wav")
			ui_player.pitch_scale = 1.0
			ui_player.play()
		"unlock":
			ui_player.stream = preload("res://audio/ui/button_click.wav")
			ui_player.pitch_scale = 1.2
			ui_player.play()
			ui_player.pitch_scale = 1.0

func play_hover_sound():
	if not hover_player:
		return
	
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
		if dialog_manager:
			dialog_manager.cleanup()

		if GlobalMusicManager and GlobalMusicManager.is_challenge_music_playing():
			GlobalMusicManager.stop_all_music(0.3)
	elif what == NOTIFICATION_RESIZED:
		if adaptive_columns:
			call_deferred("setup_responsive_layout")
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		if accessed_from_game:
			GameStateManager.clear_saved_state()
