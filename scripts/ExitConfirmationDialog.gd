class_name ExitConfirmationDialog
extends RefCounted

var main_scene: Control
var confirmation_overlay: Control
var confirmation_background: ColorRect
var confirmation_panel: Panel
var confirmation_label: Label
var confirm_button: Button
var cancel_button: Button
var is_showing: bool = false

var custom_title: String = ""
var custom_message: String = ""
var confirm_text: String = "YES, RETURN"
var cancel_text: String = "CANCEL"

# Input handling node
var input_blocker: Control

func setup(main: Control, title: String = "", message: String = ""):
	main_scene = main
	if title != "":
		custom_title = title
	if message != "":
		custom_message = message
	_create_confirmation_dialog()

func _create_confirmation_dialog():
	# Crear input blocker como primer hijo (captura input primero)
	input_blocker = Control.new()
	input_blocker.name = "InputBlocker"
	input_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	input_blocker.focus_mode = Control.FOCUS_ALL
	input_blocker.visible = false
	input_blocker.z_index = 99
	main_scene.add_child(input_blocker)
	
	confirmation_overlay = Control.new()
	confirmation_overlay.name = "ConfirmationOverlay"
	confirmation_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirmation_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	confirmation_overlay.visible = false
	confirmation_overlay.z_index = 100
	main_scene.add_child(confirmation_overlay)
	
	confirmation_background = ColorRect.new()
	confirmation_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirmation_background.color = Color(0, 0, 0, 0.7)
	confirmation_background.mouse_filter = Control.MOUSE_FILTER_STOP
	confirmation_overlay.add_child(confirmation_background)

	confirmation_panel = Panel.new()
	confirmation_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	confirmation_panel.custom_minimum_size = Vector2(400, 200)
	confirmation_panel.size = Vector2(400, 200)
	confirmation_panel.position = Vector2(-200, -100)
	confirmation_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	confirmation_overlay.add_child(confirmation_panel)
	
	_setup_panel_content()
	_setup_buttons()
	_connect_signals()

func _setup_panel_content():
	var panel_bg = ColorRect.new()
	panel_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_bg.color = Color(0.15, 0.15, 0.25, 0.95)
	panel_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	confirmation_panel.add_child(panel_bg)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	confirmation_panel.add_child(vbox)

	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	spacer1.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(spacer1)

	confirmation_label = Label.new()
	if custom_message != "":
		confirmation_label.text = custom_message
	else:
		confirmation_label.text = "Return to main menu?\nCurrent progress will be lost"
	
	confirmation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirmation_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	confirmation_label.add_theme_font_size_override("font_size", 16)
	confirmation_label.add_theme_color_override("font_color", Color.WHITE)
	confirmation_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	confirmation_label.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(confirmation_label)
	
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 30)
	button_container.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(button_container)
	
	confirm_button = Button.new()
	confirm_button.text = confirm_text
	confirm_button.custom_minimum_size = Vector2(140, 45)
	confirm_button.add_theme_font_size_override("font_size", 14)
	confirm_button.focus_mode = Control.FOCUS_ALL
	button_container.add_child(confirm_button)
	
	cancel_button = Button.new()
	cancel_button.text = cancel_text
	cancel_button.custom_minimum_size = Vector2(140, 45)
	cancel_button.add_theme_font_size_override("font_size", 14)
	cancel_button.focus_mode = Control.FOCUS_ALL
	button_container.add_child(cancel_button)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	spacer2.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(spacer2)

func _setup_buttons():
	confirm_button.focus_neighbor_right = cancel_button.get_path()
	cancel_button.focus_neighbor_left = confirm_button.get_path()
	
	# Evitar que el focus escape del diálogo
	confirm_button.focus_neighbor_left = cancel_button.get_path()
	cancel_button.focus_neighbor_right = confirm_button.get_path()
	confirm_button.focus_neighbor_top = confirm_button.get_path()
	confirm_button.focus_neighbor_bottom = confirm_button.get_path()
	cancel_button.focus_neighbor_top = cancel_button.get_path()
	cancel_button.focus_neighbor_bottom = cancel_button.get_path()

func _connect_signals():
	confirm_button.pressed.connect(_on_confirm_exit)
	cancel_button.pressed.connect(_on_cancel_exit)
	
	confirm_button.mouse_entered.connect(_on_button_hover.bind(confirm_button))
	cancel_button.mouse_entered.connect(_on_button_hover.bind(cancel_button))
	confirm_button.focus_entered.connect(_on_button_focus.bind(confirm_button))
	cancel_button.focus_entered.connect(_on_button_focus.bind(cancel_button))
	
	# Conectar el input blocker para capturar y procesar input
	input_blocker.gui_input.connect(_on_input_blocker_input)

func set_options_context():
	custom_message = "Exit without saving?\nUnsaved changes will be lost"
	confirm_text = "YES, EXIT"
	cancel_text = "STAY IN MENU"
	
	if confirmation_label:
		confirmation_label.text = custom_message
	if confirm_button:
		confirm_button.text = confirm_text
	if cancel_button:
		cancel_button.text = cancel_text

func show():
	if is_showing:
		return
	
	is_showing = true
	
	# Activar el bloqueador de input
	input_blocker.visible = true
	input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	
	confirmation_overlay.visible = true
	confirmation_overlay.modulate.a = 0.0
	
	var tween = main_scene.create_tween()
	tween.tween_property(confirmation_overlay, "modulate:a", 1.0, 0.3)
	
	await tween.finished
	
	# Dar focus al botón de cancelar
	cancel_button.grab_focus()

func hide():
	if not is_showing:
		return
	
	var tween = main_scene.create_tween()
	tween.tween_property(confirmation_overlay, "modulate:a", 0.0, 0.2)
	
	await tween.finished
	
	confirmation_overlay.visible = false
	input_blocker.visible = false
	input_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_showing = false
	
	# Reactivar input del InputManager
	if main_scene.has_method("get") and main_scene.get("input_manager"):
		main_scene.input_manager.enable_input()

func _on_input_blocker_input(event: InputEvent):
	if not is_showing:
		return
	
	# Procesar el input aquí para que no llegue a otros controles
	handle_input(event)
	
	# Marcar el evento como manejado para que no se propague
	if confirmation_overlay.visible:
		main_scene.get_viewport().set_input_as_handled()

func handle_input(event: InputEvent):
	if not is_showing:
		return
	
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("game_select"):
		if confirm_button.has_focus():
			_on_confirm_exit()
		elif cancel_button.has_focus():
			_on_cancel_exit()
		main_scene.get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("game_back"):
		_on_cancel_exit()
		main_scene.get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("ui_left"):
		confirm_button.grab_focus()
		main_scene.get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("ui_right"):
		cancel_button.grab_focus()
		main_scene.get_viewport().set_input_as_handled()

func _on_confirm_exit():
	if main_scene.has_method("_play_ui_sound"):
		main_scene._play_ui_sound("notification")
	
	is_showing = false
	input_blocker.visible = false
	
	if main_scene.has_method("return_to_menu"):
		main_scene.return_to_menu()
	elif main_scene.has_method("_on_confirmation_exit_confirmed"):
		main_scene._on_confirmation_exit_confirmed()

func _on_cancel_exit():
	if main_scene.has_method("get") and main_scene.get("audio_helper"):
		main_scene.audio_helper.play_card_hover_sound()
	elif main_scene.has_method("_play_ui_sound"):
		main_scene._play_ui_sound("ui_focus")
	
	hide()
	
	if main_scene.has_method("_on_confirmation_canceled"):
		main_scene._on_confirmation_canceled()

func _on_button_hover(button: Button):
	if main_scene.has_method("get") and main_scene.get("audio_helper"):
		main_scene.audio_helper.play_card_hover_sound()
	elif main_scene.has_method("_play_ui_sound"):
		main_scene._play_ui_sound("ui_focus")
	
	var tween = main_scene.create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	
	if not button.mouse_exited.is_connected(_on_button_unhover):
		button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_unhover(button: Button):
	var tween = main_scene.create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_button_focus(button: Button):
	if main_scene.has_method("get") and main_scene.get("audio_helper"):
		main_scene.audio_helper.play_card_hover_sound()
	elif main_scene.has_method("_play_ui_sound"):
		main_scene._play_ui_sound("ui_focus")
	
	var tween = main_scene.create_tween()
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)
	
	if not button.focus_exited.is_connected(_on_button_unfocus):
		button.focus_exited.connect(_on_button_unfocus.bind(button))

func _on_button_unfocus(button: Button):
	var tween = main_scene.create_tween()
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
