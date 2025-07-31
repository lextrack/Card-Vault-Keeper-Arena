class_name InputManager
extends RefCounted

var main_scene: Control
var gamepad_mode: bool = false
var last_input_was_gamepad: bool = false
var options_menu: OptionsMenu
var input_enabled: bool = true

func setup(main: Control, options: OptionsMenu = null):
	main_scene = main
	options_menu = options
	_setup_button_navigation()
	
	if options_menu:
		options_menu.options_closed.connect(_on_options_menu_closed)

func _setup_button_navigation():
	var end_turn_button = main_scene.end_turn_button
	if not end_turn_button:
		push_error("EndTurnButton no encontrado en la escena")
		return
		
	end_turn_button.pressed.connect(main_scene._on_end_turn_pressed)
	end_turn_button.focus_mode = Control.FOCUS_ALL
	
	end_turn_button.focus_entered.connect(_on_button_focus.bind(end_turn_button))
	end_turn_button.mouse_exited.connect(_on_button_unhover.bind(end_turn_button))
	end_turn_button.focus_exited.connect(_on_button_unfocus.bind(end_turn_button))

func enable_input():
	input_enabled = true

func disable_input():
	input_enabled = false
	gamepad_mode = false

func is_input_enabled() -> bool:
	return input_enabled and not _is_menu_blocking_input()

func _is_menu_blocking_input() -> bool:
	if options_menu and options_menu.visible:
		return true
	return false

func start_player_turn():
	if not is_input_enabled():
		return
		
	gamepad_mode = last_input_was_gamepad
	var end_turn_button = main_scene.end_turn_button
	
	_update_controls_panel()
	main_scene.ui_manager.selected_card_index = 0
	main_scene.ui_manager.update_card_selection(gamepad_mode, main_scene.player)

func start_ai_turn():
	gamepad_mode = false
	main_scene.ui_manager.update_hand_display(main_scene.player, main_scene.card_scene, main_scene.hand_container)

func handle_input(event: InputEvent):
	if not is_input_enabled():
		return
		
	_detect_input_method(event)
	
	if event.is_action_pressed("show_options") or event.is_action_pressed("ui_menu"):
		_handle_options_menu_toggle()
		return
	elif event.is_action_pressed("game_controls"):
		_handle_controls_toggle()
	elif event.is_action_pressed("game_restart"):
		main_scene.restart_game()
	elif event.is_action_pressed("game_exit"):
		main_scene.show_exit_confirmation()
	elif main_scene.is_player_turn and gamepad_mode and main_scene.player:
		_handle_gamepad_navigation(event)

func _handle_options_menu_toggle():
	if not options_menu:
		return
	
	if options_menu.visible:
		options_menu.hide_options()
	else:
		options_menu.show_options()
		disable_input()

func _on_options_menu_closed():
	enable_input()
	
	if main_scene.is_player_turn and gamepad_mode:
		var end_turn_button = main_scene.end_turn_button
		if end_turn_button:
			end_turn_button.grab_focus()

func _detect_input_method(event: InputEvent):
	if event is InputEventJoypadButton and event.pressed:
		if not last_input_was_gamepad:
			last_input_was_gamepad = true
			if main_scene.is_player_turn and main_scene.player and is_input_enabled():
				gamepad_mode = true
				_update_ui_for_gamepad_mode()
	elif event is InputEventMouse or (event is InputEventKey and event.pressed):
		if last_input_was_gamepad:
			last_input_was_gamepad = false
			if main_scene.is_player_turn and main_scene.player and is_input_enabled():
				gamepad_mode = false
				_update_ui_for_gamepad_mode()

func _update_ui_for_gamepad_mode():
	if not is_input_enabled():
		return
		
	main_scene.ui_manager.update_card_selection(gamepad_mode, main_scene.player)
	main_scene.ui_manager.update_turn_button_text(main_scene.player, main_scene.end_turn_button, gamepad_mode)
	_update_controls_panel()

func _update_controls_panel():
	var controls_panel = main_scene.controls_panel
	if controls_panel:
		controls_panel.update_gamepad_mode(gamepad_mode)

func _handle_controls_toggle():
	if not is_input_enabled() or not main_scene.is_player_turn:
		return
		
	var controls_panel = main_scene.controls_panel
	if controls_panel:
		controls_panel.toggle_visibility()
		main_scene.audio_helper.play_card_hover_sound()

func _handle_gamepad_navigation(event: InputEvent):
	if not is_input_enabled():
		return
		
	if event.is_action_pressed("ui_left"):
		if main_scene.ui_manager.navigate_cards(-1, main_scene.player):
			main_scene.audio_helper.play_card_hover_sound()
	elif event.is_action_pressed("ui_right"):
		if main_scene.ui_manager.navigate_cards(1, main_scene.player):
			main_scene.audio_helper.play_card_hover_sound()
	elif event.is_action_pressed("game_select"):
		var selected_card = main_scene.ui_manager.get_selected_card()
		if selected_card:
			selected_card.play_selection_animation()
			main_scene._on_card_clicked(selected_card)
	elif event.is_action_pressed("game_back"):
		var end_turn_button = main_scene.end_turn_button
		if end_turn_button and not end_turn_button.disabled:
			end_turn_button.release_focus()
			main_scene._on_end_turn_pressed()

func _on_button_focus(button: Button):
	if not is_input_enabled():
		return
		
	main_scene.audio_helper.play_ui_click_sound()
	
	var tween = main_scene.create_tween()
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)

func _on_button_unhover(button: Button):
	if not gamepad_mode:
		var tween = main_scene.create_tween()
		tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

func _on_button_unfocus(button: Button):
	var tween = main_scene.create_tween()
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
