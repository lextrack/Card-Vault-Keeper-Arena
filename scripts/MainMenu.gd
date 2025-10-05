extends Control

@onready var play_button = $MenuContainer/ButtonsContainer/PlayButton
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
	
	_apply_initial_video_settings()
	
	if TransitionManager and TransitionManager.current_overlay:
		if TransitionManager.current_overlay.is_covering():
			returning_from_menu = true
	
	await handle_scene_entrance()

	start_menu_music()
	
	_focus_first_button()
	
	_setup_options_menu()
	
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

func _focus_first_button():
	if focusable_buttons.size() > 0 and focusable_buttons[0]:
		current_focus_index = 0
		focusable_buttons[0].grab_focus()

func _detect_input_method(event: InputEvent):
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
	for button in focusable_buttons:
		if button and is_instance_valid(button):
			if button.has_method("create_tween"):
				var tween = button.create_tween()
				tween.kill()
			
			button.modulate = Color(1.0, 1.0, 1.0, 1.0)
			button.scale = Vector2(1.0, 1.0)
			
func _on_input_method_changed():
	if gamepad_mode and not get_viewport().gui_get_focus_owner():
		_focus_first_button()

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
			play_entrance_animation()
	else:
		play_entrance_animation()

func _reset_menu_state():
	returning_from_menu = false
	is_transitioning = false
	popup_active = false
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
	
	var buttons = [play_button, options_button, help_button, challenge_button, credits_button, stats_button, exit_button]
	for button in buttons:
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
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(game_title, "modulate", Color(1.3, 1.3, 1.0, 1.0), title_pulse_duration)
	tween.tween_property(game_title, "modulate", Color(0.8, 0.8, 0.7, 1.0), title_pulse_duration)
	tween.tween_property(game_title, "position:y", game_title.position.y + 10, title_pulse_duration)
	tween.tween_property(game_title, "position:y", game_title.position.y, title_pulse_duration)

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
	
	if gamepad_mode:
		_focus_first_button()

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

func _on_exit_pressed():
	if is_transitioning or popup_active:
		return
	
	play_ui_sound("button_click")
	exit_game()

func _on_button_hover(button: Button):
	if popup_active or not is_instance_valid(button) or is_transitioning:
		return
	
	if not gamepad_mode or (gamepad_mode and button.has_focus()):
		play_hover_sound()
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, "scale", Vector2(1.03, 1.03), 0.2)
		tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.1, 1.0), 0.2) # Blanco cálido suave

func _on_button_unhover(button: Button):
	if not is_instance_valid(button):
		return
	
	if not gamepad_mode or (gamepad_mode and not button.has_focus()):
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
		tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func _on_button_focus(button: Button):
	if popup_active or not is_instance_valid(button) or is_transitioning:
		return
	
	if gamepad_mode:
		play_hover_sound()
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, "scale", Vector2(1.04, 1.04), 0.2)
		tween.tween_property(button, "modulate", Color(0.9, 1.1, 1.3, 1.0), 0.2) # Azul claro para foco
		tween.tween_property(button, "position:y", button.position.y - 3.0, 0.2) # Subida sutil
	
	var index = focusable_buttons.find(button)
	if index != -1:
		current_focus_index = index

func _on_button_unfocus(button: Button):
	if not is_instance_valid(button):
		return
	
	if gamepad_mode:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
		tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
		tween.tween_property(button, "position:y", button.position.y + 3.0, 0.2)


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
	if target_button:
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
	_reset_menu_state()
	resume_menu_music()
	set_card_rain_active(true)
