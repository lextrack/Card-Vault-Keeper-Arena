class_name InputManager
extends Node

var main_scene: Control
var options_menu: OptionsMenu
var last_interaction_time: float = 0.0

var _button_tweens: Dictionary = {}

func setup(main: Control, options: OptionsMenu = null):
	main_scene = main
	options_menu = options
	_setup_button_navigation()
	
	if options_menu:
		options_menu.options_closed.connect(_on_options_menu_closed)
	
	GameState.gamepad_mode_changed.connect(_on_gamepad_mode_changed)
	GameState.input_enabled_changed.connect(_on_input_enabled_changed)

func _setup_button_navigation():
	var end_turn_button = main_scene.end_turn_button
	if not end_turn_button:
		push_error("EndTurnButton not found")
		return
		
	end_turn_button.pressed.connect(main_scene._on_end_turn_pressed)
	end_turn_button.focus_mode = Control.FOCUS_ALL
	
	end_turn_button.focus_entered.connect(_on_button_focus.bind(end_turn_button))
	end_turn_button.mouse_exited.connect(_on_button_unhover.bind(end_turn_button))
	end_turn_button.focus_exited.connect(_on_button_unfocus.bind(end_turn_button))

func _on_gamepad_mode_changed(enabled: bool):
	if main_scene.is_player_turn and is_input_enabled():
		_update_ui_for_gamepad_mode()

func _on_input_enabled_changed(enabled: bool):
	pass

func enable_input():
	GameState.input_enabled = true
	GameState.is_processing_input = false
	
	if GameState.gamepad_mode:
		_update_ui_for_gamepad_mode()

func disable_input():
	GameState.input_enabled = false
	GameState.gamepad_mode = false
	GameState.is_processing_input = false

func is_input_enabled() -> bool:
	return GameState.can_process_input() and not _is_menu_blocking_input() and not _is_game_transitioning()

func _is_menu_blocking_input() -> bool:
	# Verificar si el popup de confirmación está abierto
	if main_scene.has_method("get") and main_scene.get("exit_dialog"):
		var exit_dialog = main_scene.exit_dialog
		if exit_dialog and exit_dialog.is_showing:
			return true
	
	if options_menu and options_menu.visible:
		return true
	return false

func _is_game_transitioning() -> bool:
	if main_scene and main_scene.has_method("get") and main_scene.get("is_game_transitioning"):
		return main_scene.is_game_transitioning
	return false

func sync_gamepad_state():
	if not is_input_enabled():
		return
	
	if GameState.gamepad_mode and main_scene.is_player_turn:
		if not main_scene.ui_manager.gamepad_selection_active:
			main_scene.ui_manager.gamepad_selection_active = true
			main_scene.ui_manager.update_card_selection(true, main_scene.player)

func start_player_turn():
	if not is_input_enabled() or _is_game_transitioning():
		return
		
	GameState.is_processing_input = false
	
	var end_turn_button = main_scene.end_turn_button
	
	if end_turn_button:
		main_scene.ui_manager.reset_turn_button(end_turn_button, GameState.gamepad_mode)
	
	_update_controls_panel()
	main_scene.ui_manager.selected_card_index = 0
	
	if GameState.gamepad_mode:
		main_scene.ui_manager.gamepad_selection_active = true
	
	main_scene.ui_manager.update_card_selection(GameState.gamepad_mode, main_scene.player)
	
	if end_turn_button and main_scene.player:
		main_scene.ui_manager.update_turn_button_text(main_scene.player, end_turn_button, GameState.gamepad_mode)

func start_ai_turn():
	GameState.is_processing_input = false

	main_scene.ui_manager.gamepad_selection_active = false
	main_scene.ui_manager.update_card_selection(false, main_scene.player)
	main_scene.ui_manager.update_hand_display(main_scene.player, main_scene.card_scene, main_scene.hand_container)

func handle_input(event: InputEvent):
	if not is_input_enabled():
		return
		
	_detect_input_method(event)

	if _is_game_transitioning():
		return
	
	if event.is_action_pressed("show_options") or event.is_action_pressed("ui_menu"):
		_handle_options_menu_toggle()
		return
	elif event.is_action_pressed("game_controls"):
		_handle_controls_toggle()
	elif event.is_action_pressed("end_turn_specific"):
		_handle_end_turn_input()
	elif event.is_action_pressed("game_restart"):
		if not _is_game_transitioning():
			main_scene.restart_game()
	elif event.is_action_pressed("game_exit"):
		if not _is_game_transitioning():
			main_scene.show_exit_confirmation()
	elif main_scene.is_player_turn and (GameState.gamepad_mode or event is InputEventKey) and main_scene.player and not _is_game_transitioning():
		_handle_keyboard_and_gamepad_navigation(event)

func _handle_options_menu_toggle():
	if not options_menu:
		return
	
	if options_menu.visible:
		options_menu.hide_options()
	else:
		options_menu.show_options()

func _on_options_menu_closed():
	enable_input()

	if main_scene.is_player_turn and GameState.gamepad_mode:
		var end_turn_button = main_scene.end_turn_button
		if end_turn_button:
			end_turn_button.grab_focus()

func _detect_input_method(event: InputEvent):
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if event is InputEventJoypadButton and event.pressed:
		if not GameState.gamepad_mode:
			GameState.gamepad_mode = true
			last_interaction_time = current_time
			
			if main_scene.is_player_turn and main_scene.player and is_input_enabled():
				_switch_to_gamepad_mode()
				
	elif event is InputEventMouse:
		if current_time - last_interaction_time > 0.1:
			if GameState.gamepad_mode:
				GameState.gamepad_mode = false
				last_interaction_time = current_time
				
				if main_scene.is_player_turn and main_scene.player and is_input_enabled():
					_switch_to_mouse_mode()
					
	elif event is InputEventKey and event.pressed:
		if not GameState.gamepad_mode and current_time - last_interaction_time > 0.3:
			last_interaction_time = current_time

func _switch_to_gamepad_mode():
	_update_ui_for_gamepad_mode()
	main_scene.audio_helper.play_ui_click_sound()

func _switch_to_mouse_mode():
	_update_ui_for_gamepad_mode()

func _update_ui_for_gamepad_mode():
	if not is_input_enabled():
		return
		
	if GameState.gamepad_mode:
		main_scene.ui_manager.gamepad_selection_active = true
	else:
		main_scene.ui_manager.gamepad_selection_active = false
		main_scene.ui_manager._clear_all_gamepad_selection_styles()
	
	main_scene.ui_manager.update_card_selection(GameState.gamepad_mode, main_scene.player)
	main_scene.ui_manager.update_turn_button_text(main_scene.player, main_scene.end_turn_button, GameState.gamepad_mode)
	_update_controls_panel()

func _update_controls_panel():
	var controls_panel = main_scene.controls_panel
	if controls_panel:
		controls_panel.update_gamepad_mode(GameState.gamepad_mode)

func _handle_controls_toggle():
	if not is_input_enabled() or not main_scene.is_player_turn or _is_game_transitioning():
		return
		
	var controls_panel = main_scene.controls_panel
	if controls_panel:
		controls_panel.toggle_visibility()
		main_scene.audio_helper.play_card_hover_sound()

func _handle_keyboard_and_gamepad_navigation(event: InputEvent):
	if not is_input_enabled() or _is_game_transitioning():
		return
	
	if event.is_action_pressed("ui_left"):
		if main_scene.ui_manager.navigate_cards(-1, main_scene.player):
			main_scene.ui_manager.handle_card_hover_audio(null, "gamepad_navigation")
		return
	elif event.is_action_pressed("ui_right"):
		if main_scene.ui_manager.navigate_cards(1, main_scene.player):
			main_scene.ui_manager.handle_card_hover_audio(null, "gamepad_navigation")
		return

	if main_scene.player.can_play_more_cards():
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("game_select"):
			_handle_card_selection()
			return
			
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("game_back"):
		_handle_end_turn_input()
		return

func _handle_card_selection():
	if GameState.is_processing_input:
		return
	
	if not main_scene.player.can_play_more_cards():
		if main_scene.audio_helper.has_method("play_error_sound"):
			main_scene.audio_helper.play_error_sound()
		else:
			main_scene.audio_helper.play_ui_click_sound()
		return
		
	var selected_card = main_scene.ui_manager.get_selected_card()
	if not selected_card or not selected_card.has_method("get_card_data"):
		return
		
	var card_data = selected_card.get_card_data()
	if not main_scene.player.can_play_card(card_data):
		selected_card.animate_mana_insufficient()
		return
		
	GameState.is_processing_input = true
	main_scene._on_card_clicked(selected_card)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	GameState.is_processing_input = false

func _handle_end_turn_input():
	var end_turn_button = main_scene.end_turn_button
	if end_turn_button and not end_turn_button.disabled:
		end_turn_button.release_focus()
		main_scene._on_end_turn_pressed()

func _on_button_focus(button: Button):
	if not is_input_enabled():
		return
		
	main_scene.audio_helper.play_ui_click_sound()
	
	if _button_tweens.has(button) and _button_tweens[button].is_valid():
		_button_tweens[button].kill()
	
	_button_tweens[button] = create_tween()
	_button_tweens[button].tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)

func _on_button_unhover(button: Button):
	if not GameState.gamepad_mode:
		if _button_tweens.has(button) and _button_tweens[button].is_valid():
			_button_tweens[button].kill()
		
		_button_tweens[button] = create_tween()
		_button_tweens[button].tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

func _on_button_unfocus(button: Button):
	if _button_tweens.has(button) and _button_tweens[button].is_valid():
		_button_tweens[button].kill()
	
	_button_tweens[button] = create_tween()
	_button_tweens[button].tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		for tween in _button_tweens.values():
			if tween and tween.is_valid():
				tween.kill()
		_button_tweens.clear()
