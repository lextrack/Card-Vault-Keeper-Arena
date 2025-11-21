extends Control

@onready var play_button = $MenuContainer/ButtonsContainer/PlayButton
@onready var run_mode_button = $MenuContainer/ButtonsContainer/RunModeButton
@onready var options_button = $MenuContainer/ButtonsContainer/OptionsButton
@onready var help_button = $MenuContainer/ButtonsContainer/HelpButton
@onready var credits_button = $MenuContainer/ButtonsContainer/CreditsButton
@onready var exit_button = $MenuContainer/ButtonsContainer/ExitButton
@onready var stats_button = $MenuContainer/ButtonsContainer/StatsButton
@onready var challenge_button = $MenuContainer/ButtonsContainer/ChallengeButton

@onready var game_title = $MenuContainer/TitleContainer/GameTitle
@onready var version_label = $FooterContainer/VersionLabel
@onready var transition_layer = $TransitionLayer
@onready var transition_label = $TransitionLayer/TransitionLabel

@onready var menu_music_player = $AudioManager/MenuMusicPlayer
@onready var ui_player = $AudioManager/UIPlayer
@onready var hover_player = $AudioManager/HoverPlayer
@onready var card_rain_background = $BackgroundLayer/CardRainBackground

var options_menu: OptionsMenu
var is_transitioning: bool = false
var music_fade_tween: Tween
var gamepad_mode: bool = false
var last_input_was_gamepad: bool = false
var popup_active: bool = false
var focusable_buttons: Array[Button] = []
var current_focus_index: int = 0
var returning_from_menu: bool = false
var entrance_complete: bool = false

const COLOR_NORMAL = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_HOVER = Color(1.113, 1.207, 1.3, 1.0)
const COLOR_FOCUS = Color(1.2, 1.3, 1.4, 1.0)
const SCALE_NORMAL = Vector2(1.0, 1.0)
const SCALE_HOVER = Vector2(1.03, 1.03)
const SCALE_FOCUS = Vector2(1.05, 1.05)
const HOVER_LIFT = 3.0

const ANIM_DURATION = 0.18
const ANIM_EASE = Tween.EASE_OUT
const ANIM_EASE_IN = Tween.EASE_IN
const ANIM_TRANS = Tween.TRANS_CUBIC

@export var entrance_duration: float = 0.8
@export var scale_duration: float = 0.6
@export var title_pulse_duration: float = 1.5
@export var initial_scale: Vector2 = Vector2(3.0, 1.5)
@export var entry_offset_y: float = -50.0

@export var options_menu_scene: PackedScene = preload("res://scenes/OptionsMenu.tscn")

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_buttons()
	setup_audio()
	_setup_gamepad_navigation()
	_hide_exit_button_on_web()
	_apply_initial_video_settings()
	
	if TransitionManager and TransitionManager.current_overlay:
		if TransitionManager.current_overlay.is_covering():
			returning_from_menu = true
	
	await handle_scene_entrance()
	start_menu_music()
	
	entrance_complete = true
	
	_save_original_button_positions()
	
	
	await get_tree().process_frame
	_focus_first_button_safe()
	
	_setup_options_menu()
	
func _hide_exit_button_on_web():
	if OS.has_feature("web") or OS.get_name() == "Web":
		if exit_button:
			for button in focusable_buttons:
				if button and button != exit_button:
					if button.focus_neighbor_top == exit_button.get_path():
						button.focus_neighbor_top = NodePath()
					if button.focus_neighbor_bottom == exit_button.get_path():
						button.focus_neighbor_bottom = NodePath()
					if button.focus_neighbor_left == exit_button.get_path():
						button.focus_neighbor_left = NodePath()
					if button.focus_neighbor_right == exit_button.get_path():
						button.focus_neighbor_right = NodePath()
			
			var index = focusable_buttons.find(exit_button)
			if index != -1:
				focusable_buttons.remove_at(index)

			exit_button.visible = false
			exit_button.queue_free()
			
			_reconfigure_navigation_without_exit()

func _reconfigure_navigation_without_exit():
	if stats_button and play_button:
		stats_button.focus_neighbor_bottom = play_button.get_path()
		play_button.focus_neighbor_top = stats_button.get_path()

func _save_original_button_positions():
	var buttons = [play_button, options_button, help_button, challenge_button, credits_button, stats_button, exit_button]
	for button in buttons:
		if button and is_instance_valid(button):
			button.set_meta("original_y", button.position.y)

func set_card_rain_intensity(intensity: float):
	if card_rain_background:
		card_rain_background.set_effect_intensity(intensity)

func set_card_rain_active(active: bool):
	if card_rain_background:
		card_rain_background.set_effect_active(active)
	
func _apply_initial_video_settings():
	var config = ConfigFile.new()
	var err = config.load("user://video_settings.cfg")
	
	if err != OK:
		print("No video configuration found, using default values")
		return
	
	var window_mode = config.get_value("video", "window_mode", 0)
	var resolution_index = config.get_value("video", "resolution_index", 3)
	var vsync_enabled = config.get_value("video", "vsync_enabled", true)
	
	var available_resolutions = [
		Vector2i(1366, 768),
		Vector2i(1600, 900),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440),
		Vector2i(3840, 2160)
	]
	
	var window = get_window()
	if not window:
		return
	
	match window_mode:
		0:
			window.mode = Window.MODE_WINDOWED
		1:
			window.mode = Window.MODE_FULLSCREEN
		2:
			window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	
	if window_mode == 0 and resolution_index < available_resolutions.size():
		var target_resolution = available_resolutions[resolution_index]
		window.size = target_resolution
		
		var screen_size = DisplayServer.screen_get_size()
		window.position = (screen_size - target_resolution) / 2
	
	if vsync_enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _setup_options_menu():
	options_menu = options_menu_scene.instantiate()
	options_menu.setup(null, false)
	options_menu.options_closed.connect(_on_options_menu_closed)
	add_child(options_menu)
	options_menu.visible = false
	options_menu.apply_startup_settings()

func _setup_gamepad_navigation():
	focusable_buttons = [
		play_button,
		run_mode_button,
		options_button,
		help_button,
		challenge_button,
		credits_button,
		stats_button,
		exit_button
	]
	
	for i in range(focusable_buttons.size()):
		var button = focusable_buttons[i]
		if button:
			button.focus_mode = Control.FOCUS_ALL
			
			var next_index = (i + 1) % focusable_buttons.size()
			var prev_index = (i - 1) % focusable_buttons.size()
			if prev_index < 0:
				prev_index = focusable_buttons.size() - 1
			
			if focusable_buttons[next_index]:
				button.focus_neighbor_bottom = focusable_buttons[next_index].get_path()
			if focusable_buttons[prev_index]:
				button.focus_neighbor_top = focusable_buttons[prev_index].get_path()

func _focus_first_button_safe():
	if not entrance_complete:
		return
	
	if focusable_buttons.size() > 0 and focusable_buttons[0] and is_instance_valid(focusable_buttons[0]) and gamepad_mode == true:
		current_focus_index = 0
		if not is_transitioning and not popup_active:
			focusable_buttons[0].grab_focus()

func _detect_input_method(event: InputEvent):
	if event is InputEventJoypadMotion:
		if abs(event.axis_value) < 0.3:
			return
	
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if not gamepad_mode:
			gamepad_mode = true
			last_input_was_gamepad = true
			CursorManager.set_gamepad_mode(true)
			_reset_all_button_effects()
			_on_input_method_changed()
	elif event is InputEventMouse or event is InputEventKey:
		if gamepad_mode:
			gamepad_mode = false
			last_input_was_gamepad = false
			CursorManager.set_gamepad_mode(false)
			_reset_all_button_effects()
			_on_input_method_changed()

func _reset_all_button_effects():
	var had_focus = get_viewport().gui_get_focus_owner()
	var focus_index = -1
	
	if had_focus is Button and had_focus in focusable_buttons:
		focus_index = focusable_buttons.find(had_focus)
	
	for button in focusable_buttons:
		if button and is_instance_valid(button):
			if button.has_method("create_tween"):
				var tween = button.create_tween()
				tween.kill()
			
			button.modulate = COLOR_NORMAL
			button.scale = SCALE_NORMAL

			if button.has_meta("original_y"):
				button.position.y = button.get_meta("original_y")
	
	if focus_index >= 0 and entrance_complete and not is_transitioning:
		await get_tree().process_frame
		if focusable_buttons[focus_index] and is_instance_valid(focusable_buttons[focus_index]):
			focusable_buttons[focus_index].grab_focus()
			
func _on_input_method_changed():
	if gamepad_mode and not get_viewport().gui_get_focus_owner() and entrance_complete:
		_focus_first_button_safe()

func setup_audio():
	if menu_music_player and menu_music_player.stream and GlobalMusicManager:
		if not GlobalMusicManager.menu_music_player.stream:
			GlobalMusicManager.set_menu_music_stream(menu_music_player.stream)
		else:
			print("Menu music stream already configured in GlobalMusicManager")

func start_menu_music():
	if GlobalMusicManager:
		GlobalMusicManager.start_menu_music()
	else:
		print("GlobalMusicManager not available")

func stop_menu_music(fade_duration: float = 1.0):
	if GlobalMusicManager:
		GlobalMusicManager.stop_menu_music_for_game(fade_duration)
	else:
		print("GlobalMusicManager not available")

func resume_menu_music():
	start_menu_music()

func handle_scene_entrance():
	await get_tree().process_frame
	
	if TransitionManager and TransitionManager.current_overlay:
		if (TransitionManager.current_overlay.has_method("is_ready") and
			TransitionManager.current_overlay.is_ready() and
			TransitionManager.current_overlay.has_method("is_covering") and
			TransitionManager.current_overlay.is_covering()):

			if returning_from_menu:
				await TransitionManager.current_overlay.fade_out(0.8)
				_reset_menu_state()
			else:
				await TransitionManager.current_overlay.fade_out(0.8)
		else:
			await play_entrance_animation()
	else:
		await play_entrance_animation()

func _reset_menu_state():
	returning_from_menu = false
	is_transitioning = false
	popup_active = false
	entrance_complete = true
	_reset_all_button_effects()
	
	set_card_rain_active(true)

func setup_buttons():
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	help_button.pressed.connect(_on_help_pressed)
	challenge_button.pressed.connect(_on_challenge_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	stats_button.pressed.connect(_on_statistics_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	if run_mode_button:
		run_mode_button.pressed.connect(_on_run_mode_pressed)
	
	var buttons = [
		play_button,
		run_mode_button,
		options_button,
		help_button,
		challenge_button,
		credits_button,
		stats_button,
		exit_button
	]
	
	for button in buttons:
		if button and is_instance_valid(button):
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.focus_entered.connect(_on_button_focus.bind(button))
			button.focus_exited.connect(_on_button_unfocus.bind(button))
			button.mouse_exited.connect(_on_button_unhover.bind(button))
		
func _on_statistics_pressed():
	if is_transitioning or popup_active:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")
	
	TransitionManager.fade_to_scene("res://scenes/StatisticsMenu.tscn", 1.0)

func play_entrance_animation():
	modulate.a = 0.0
	scale = initial_scale
	position.y = entry_offset_y

	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "modulate:a", 1.0, entrance_duration)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), scale_duration)
	tween.tween_property(self, "position:y", 0.0, entrance_duration * 0.5)

	await tween.finished
	
	if game_title:
		animate_title()
	else:
		push_warning("game_title is not assigned!")

func animate_title():
	if not game_title:
		return
	
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.set_trans(Tween.TRANS_SINE)
	glow_tween.set_ease(Tween.EASE_IN_OUT)
	
	glow_tween.tween_property(game_title, "modulate", Color(1.25, 1.25, 1.05, 1.0), 2.0)
	glow_tween.tween_property(game_title, "modulate", Color(0.9, 0.9, 0.8, 1.0), 2.0)
	
	var original_pos_y = game_title.position.y
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.set_trans(Tween.TRANS_SINE)
	float_tween.set_ease(Tween.EASE_IN_OUT)
	
	float_tween.tween_property(game_title, "position:y", original_pos_y - 6, 2.0)
	float_tween.tween_property(game_title, "position:y", original_pos_y + 6, 2.0)
	
	var scale_tween = create_tween()
	scale_tween.set_loops()
	scale_tween.set_trans(Tween.TRANS_QUAD)
	scale_tween.set_ease(Tween.EASE_IN_OUT)
	
	scale_tween.tween_property(game_title, "scale", Vector2(1.015, 1.015), 2.0)
	scale_tween.tween_property(game_title, "scale", Vector2(0.985, 0.985), 2.0)

func _on_play_pressed():
	if is_transitioning or popup_active:
		return
	
	set_card_rain_active(false)
	
	is_transitioning = true
	play_ui_sound("button_click")

	stop_menu_music(0.8)
	await get_tree().create_timer(0.3).timeout

	TransitionManager.fade_to_scene("res://scenes/DifficultyMenu.tscn", 1.0)
	
func _on_challenge_pressed():
	if is_transitioning or popup_active:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")
	
	TransitionManager.fade_to_scene("res://scenes/ChallengeHub.tscn", 1.0)

func _on_help_pressed():
	if is_transitioning or popup_active:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")
	
	TransitionManager.fade_to_scene("res://scenes/HelpMenu.tscn", 1.0)

func _on_options_pressed():
	if is_transitioning or popup_active:
		return
	
	play_ui_sound("button_click")
	show_options_menu()

func show_options_menu():
	if not options_menu:
		return
	
	is_transitioning = true
	_disable_menu_input()
	
	if TransitionManager and TransitionManager.current_overlay:
		await TransitionManager.current_overlay.fade_in(0.8)
		
		await get_tree().create_timer(0.4).timeout
		
		options_menu.show_options()
		
		await TransitionManager.current_overlay.fade_out(0.8)
	else:
		options_menu.show_options()
	
	is_transitioning = false

func _disable_menu_input():
	_reset_all_button_effects()
	
	for button in focusable_buttons:
		if button and is_instance_valid(button):
			button.focus_mode = Control.FOCUS_NONE

func _enable_menu_input():
	for button in focusable_buttons:
		if button and is_instance_valid(button):
			button.focus_mode = Control.FOCUS_ALL

	_reset_all_button_effects()
	
	if gamepad_mode and entrance_complete:
		await get_tree().process_frame
		_focus_first_button_safe()

func _on_options_menu_closed():
	print("Options menu closed in main menu")
	_show_exit_transition_immediate()

func _show_exit_transition_immediate():
	if TransitionManager and TransitionManager.current_overlay:
		await TransitionManager.ensure_overlay_exists()
		
		if TransitionManager.current_overlay.has_method("instant_black"):
			TransitionManager.current_overlay.instant_black()
		
		await get_tree().create_timer(0.4).timeout
		
		if TransitionManager.current_overlay.has_method("fade_out"):
			await TransitionManager.current_overlay.fade_out(0.8)
	
	_enable_menu_input()
	is_transitioning = false

func _on_credits_pressed():
	if is_transitioning or popup_active:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")
	
	TransitionManager.fade_to_scene("res://scenes/CreditsScene.tscn", 1.0)

func _on_run_mode_pressed():
	play_ui_sound("button_click")
	TransitionManager.fade_to_scene("res://scenes/RunManager.tscn", 1.0)
	
func _on_exit_pressed():
	if is_transitioning or popup_active:
		return
	
	play_ui_sound("button_click")
	exit_game()

func _on_button_hover(button: Button):
	if popup_active or not is_instance_valid(button) or is_transitioning:
		return
	
	if gamepad_mode:
		return
	
	button.release_focus()
	
	play_hover_sound()
	_animate_button_state(button, SCALE_HOVER, COLOR_HOVER)

func _on_button_unhover(button: Button):
	if not is_instance_valid(button):
		return
	
	if gamepad_mode:
		return
	
	button.release_focus()
	_animate_button_state(button, SCALE_NORMAL, COLOR_NORMAL, 0.0, ANIM_EASE_IN)

func _on_button_focus(button: Button):
	if popup_active or not is_instance_valid(button) or is_transitioning:
		return
	
	if gamepad_mode and entrance_complete:
		play_hover_sound()
		_animate_button_state(button, SCALE_FOCUS, COLOR_FOCUS, -HOVER_LIFT)
	
	var index = focusable_buttons.find(button)
	if index != -1:
		current_focus_index = index

func _on_button_unfocus(button: Button):
	if not is_instance_valid(button):
		return
	
	if gamepad_mode:
		_animate_button_state(button, SCALE_NORMAL, COLOR_NORMAL, HOVER_LIFT, ANIM_EASE_IN)
		
func _animate_button_state(button: Button, target_scale: Vector2, target_color: Color, lift_offset: float = 0.0, ease_type = ANIM_EASE):
	if not is_instance_valid(button):
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(ease_type)
	tween.set_trans(ANIM_TRANS)
	
	tween.tween_property(button, "scale", target_scale, ANIM_DURATION)
	tween.tween_property(button, "modulate", target_color, ANIM_DURATION)
	
	if lift_offset != 0.0:
		var original_y = button.get_meta("original_y", button.position.y)
		var target_y = original_y + lift_offset
		tween.tween_property(button, "position:y", target_y, ANIM_DURATION)

func exit_game():
	is_transitioning = true
	
	stop_menu_music(0.5)
	
	if TransitionManager.current_overlay:
		await TransitionManager.current_overlay.fade_in(0.8)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		tween.tween_property(transition_layer, "modulate:a", 1.0, 0.5)
		await tween.finished
	
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()

func play_ui_sound(sound_type: String):
	match sound_type:
		"button_click":
			ui_player.stream = preload("res://audio/ui/button_click.wav")
			ui_player.play()
			pass
		_:
			pass

func play_hover_sound():
	pass

func _navigate_focus(direction: int):
	if popup_active or focusable_buttons.size() == 0:
		return
	
	current_focus_index = (current_focus_index + direction) % focusable_buttons.size()
	if current_focus_index < 0:
		current_focus_index = focusable_buttons.size() - 1
	
	var target_button = focusable_buttons[current_focus_index]
	if target_button and is_instance_valid(target_button):
		target_button.grab_focus()

func _input(event):
	if is_transitioning:
		return
	
	_detect_input_method(event)
	
	if options_menu and options_menu.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("game_exit"):
			options_menu.hide_options()
			get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("game_back"):
		if popup_active and transition_layer.visible and transition_layer.modulate.a > 0.5:
			hide_popup()
		else:
			_on_exit_pressed()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("game_select"):
		if popup_active:
			return
			
		var focused_button = get_viewport().gui_get_focus_owner()
		if focused_button and focused_button in focusable_buttons:
			focused_button.emit_signal("pressed")
		get_viewport().set_input_as_handled()
		
	elif gamepad_mode and not popup_active:
		if event.is_action_pressed("ui_up"):
			_navigate_focus(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_down"):
			_navigate_focus(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("show_options") or event.is_action_pressed("ui_menu"):
			_on_options_pressed()
			get_viewport().set_input_as_handled()

func hide_popup():
	popup_active = false
	var tween = create_tween()
	tween.tween_property(transition_layer, "modulate:a", 0.0, 0.3)
	await tween.finished
	transition_layer.visible = false
	_enable_menu_input()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		exit_game()

func set_background_color(color: Color):
	$BackgroundLayer/BackgroundGradient.color = color

func _on_scene_entered():
	returning_from_menu = true
	entrance_complete = true
	_reset_menu_state()
	resume_menu_music()
	set_card_rain_active(true)
	
	if gamepad_mode:
		await get_tree().process_frame
		_focus_first_button_safe()
