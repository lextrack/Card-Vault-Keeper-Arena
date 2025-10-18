class_name OptionsMenu
extends Control

@onready var master_volume_slider = $MainPanel/VBoxContainer/ScrollContainer/SettingsContainer/AudioSection/AudioVBox/AudioSettingsContainer/AudioSettings/MasterVolumeContainer/MasterVolumeSlider
@onready var master_volume_label = $MainPanel/VBoxContainer/ScrollContainer/SettingsContainer/AudioSection/AudioVBox/AudioSettingsContainer/AudioSettings/MasterVolumeContainer/MasterVolumeLabel
@onready var music_volume_slider = $MainPanel/VBoxContainer/ScrollContainer/SettingsContainer/AudioSection/AudioVBox/AudioSettingsContainer/AudioSettings/MusicVolumeContainer/MusicVolumeSlider
@onready var music_volume_label = $MainPanel/VBoxContainer/ScrollContainer/SettingsContainer/AudioSection/AudioVBox/AudioSettingsContainer/AudioSettings/MusicVolumeContainer/MusicVolumeLabel
@onready var sfx_volume_slider = $MainPanel/VBoxContainer/ScrollContainer/SettingsContainer/AudioSection/AudioVBox/AudioSettingsContainer/AudioSettings/SFXVolumeContainer/SFXVolumeSlider
@onready var sfx_volume_label = $MainPanel/VBoxContainer/ScrollContainer/SettingsContainer/AudioSection/AudioVBox/AudioSettingsContainer/AudioSettings/SFXVolumeContainer/SFXVolumeLabel

@onready var window_mode_option = $MainPanel/VBoxContainer/ScrollContainer/SettingsContainer/VideoSection/VideoVBox/VideoSettingsContainer/VideoSettings/WindowModeContainer/WindowModeOption
@onready var resolution_option = $MainPanel/VBoxContainer/ScrollContainer/SettingsContainer/VideoSection/VideoVBox/VideoSettingsContainer/VideoSettings/ResolutionContainer/ResolutionOption
@onready var vsync_button = $MainPanel/VBoxContainer/ScrollContainer/SettingsContainer/VideoSection/VideoVBox/VideoSettingsContainer/VideoSettings/VsyncContainer/VsyncButton

@onready var close_button = $MainPanel/VBoxContainer/ButtonContainer/CloseButton
@onready var apply_button = $MainPanel/VBoxContainer/ButtonContainer/ApplyButton
@onready var reset_button = $MainPanel/VBoxContainer/ButtonContainer/ResetButton
@onready var scroll_container = $MainPanel/VBoxContainer/ScrollContainer
@onready var main_panel = $MainPanel
@onready var video_section = $MainPanel/VBoxContainer/ScrollContainer/SettingsContainer/VideoSection

var audio_manager: AudioManager
var is_in_game: bool = false
var game_scene: Control = null
var original_process_mode: ProcessMode
var gamepad_mode: bool = false
var last_input_was_gamepad: bool = false

var input_blocked_nodes: Array[Node] = []
var original_input_modes: Array[int] = []

var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var current_window_mode: int = 0
var current_resolution_index: int = 0
var vsync_enabled: bool = true

var saved_master_volume: float = 1.0
var saved_music_volume: float = 1.0
var saved_sfx_volume: float = 1.0
var saved_window_mode: int = 0
var saved_resolution_index: int = 0
var saved_vsync_enabled: bool = true

var applied_master_volume: float = 1.0
var applied_music_volume: float = 1.0
var applied_sfx_volume: float = 1.0
var applied_window_mode: int = 0
var applied_resolution_index: int = 0
var applied_vsync_enabled: bool = true

var confirmation_dialog: ExitConfirmationDialog

var available_resolutions: Array = [
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

var resolution_names: Array = [
	"1366 x 768",
	"1600 x 900",
	"1920 x 1080",
	"2560 x 1440",
	"3840 x 2160"
]

var window_mode_names: Array = [
	"Windowed",
	"Fullscreen",
	"Borderless Fullscreen"
]

var default_master_volume: float = 1.0
var default_music_volume: float = 0.4
var default_sfx_volume: float = 1.0
var default_window_mode: int = 0
var default_resolution_index: int = 0
var default_vsync: bool = true

var focusable_elements: Array[Control] = []
var current_focus_index: int = 0
var scroll_speed: float = 50.0

signal options_closed

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hide_video_section_on_mobile_web()
	_set_mouse_filters()
	_setup_ui_connections()
	_setup_video_options()
	_setup_sliders()
	_setup_enhanced_navigation()
	_collect_focusable_elements()
	_configure_controls_for_gamepad()
	_setup_confirmation_dialog()
	visible = false
	
	load_settings_from_files()

func _hide_video_section_on_mobile_web():
	if OS.has_feature("web") or OS.has_feature("android") or OS.get_name() == "Android":
		if video_section:
			video_section.visible = false
			video_section.queue_free()

func _set_mouse_filters():
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	if main_panel:
		main_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if scroll_container:
		scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var background_gradient = $BackgroundGradient
	var background_pattern = $BackgroundPattern
	if background_gradient:
		background_gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if background_pattern:
		background_pattern.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var interactive_controls = [
		master_volume_slider, music_volume_slider, sfx_volume_slider,
		vsync_button, window_mode_option, resolution_option,
		reset_button, apply_button, close_button
	]
	
	for control in interactive_controls:
		if control and is_instance_valid(control):
			control.mouse_filter = Control.MOUSE_FILTER_PASS

func get_current_vsync_state() -> bool:
	return DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED

func load_settings_from_files():
	_load_audio_settings_from_file()
	_load_video_settings_from_file()
	
	_copy_saved_to_applied()
	_copy_applied_to_current()

func _load_audio_settings_from_file():
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")
	
	if err != OK:
		saved_master_volume = default_master_volume
		saved_music_volume = default_music_volume
		saved_sfx_volume = default_sfx_volume
		return
	
	saved_master_volume = config.get_value("audio", "master_volume", default_master_volume)
	saved_music_volume = config.get_value("audio", "music_volume", default_music_volume)
	saved_sfx_volume = config.get_value("audio", "sfx_volume", default_sfx_volume)

func _load_video_settings_from_file():
	var config = ConfigFile.new()
	var err = config.load("user://video_settings.cfg")
	
	if err != OK:
		saved_window_mode = default_window_mode
		saved_resolution_index = default_resolution_index
		saved_vsync_enabled = default_vsync
		return
	
	saved_window_mode = config.get_value("video", "window_mode", default_window_mode)
	saved_resolution_index = config.get_value("video", "resolution_index", default_resolution_index)
	saved_vsync_enabled = config.get_value("video", "vsync_enabled", default_vsync)
	
	if saved_window_mode < 0 or saved_window_mode >= window_mode_names.size():
		saved_window_mode = default_window_mode
	
	if saved_resolution_index < 0 or saved_resolution_index >= available_resolutions.size():
		saved_resolution_index = default_resolution_index

func _copy_saved_to_applied():
	applied_master_volume = saved_master_volume
	applied_music_volume = saved_music_volume
	applied_sfx_volume = saved_sfx_volume
	applied_window_mode = saved_window_mode
	applied_resolution_index = saved_resolution_index
	applied_vsync_enabled = saved_vsync_enabled

func _copy_applied_to_current():
	master_volume = applied_master_volume
	music_volume = applied_music_volume
	sfx_volume = applied_sfx_volume
	current_window_mode = applied_window_mode
	current_resolution_index = applied_resolution_index
	vsync_enabled = applied_vsync_enabled

func _copy_current_to_applied():
	applied_master_volume = master_volume
	applied_music_volume = music_volume
	applied_sfx_volume = sfx_volume
	applied_window_mode = current_window_mode
	applied_resolution_index = current_resolution_index
	applied_vsync_enabled = vsync_enabled

func _copy_applied_to_saved():
	saved_master_volume = applied_master_volume
	saved_music_volume = applied_music_volume
	saved_sfx_volume = applied_sfx_volume
	saved_window_mode = applied_window_mode
	saved_resolution_index = applied_resolution_index
	saved_vsync_enabled = applied_vsync_enabled

func _has_unsaved_changes() -> bool:
	return (
		master_volume != applied_master_volume or
		music_volume != applied_music_volume or
		sfx_volume != applied_sfx_volume or
		current_window_mode != applied_window_mode or
		current_resolution_index != applied_resolution_index or
		vsync_enabled != applied_vsync_enabled
	)

func setup(manager: AudioManager = null, in_game: bool = false, scene: Control = null):
	audio_manager = manager
	is_in_game = in_game
	game_scene = scene

func show_options():
	_take_control()
	visible = true
	
	_copy_applied_to_current()
	_update_all_ui()
	_focus_first_element()
	_play_ui_sound("menu_open")

func hide_options():
	if _has_unsaved_changes():
		_show_unsaved_changes_dialog()
	else:
		_force_close_options()

func _show_unsaved_changes_dialog():
	if confirmation_dialog:
		confirmation_dialog.show()
		_play_ui_sound("ui_alert")

func _force_close_options():
	_release_control()
	visible = false
	options_closed.emit()
	_play_ui_sound("menu_close")

func _on_confirmation_exit_confirmed():
	_copy_applied_to_current()
	_force_close_options()

func _on_confirmation_canceled():
	_focus_first_element()

func apply_startup_settings():
	_apply_audio_settings()
	_apply_video_settings()

func _on_apply_pressed():
	_apply_current_settings()
	_copy_current_to_applied()
	_save_current_settings()
	_copy_applied_to_saved()
	_notify_all_audio_systems()
	
	_play_ui_sound("notification")
	
	_force_close_options()
	
func _notify_all_audio_systems():
	if GlobalMusicManager:
		GlobalMusicManager._load_music_settings()
	
	if is_in_game and game_scene and game_scene.has_method("get"):
		var audio_helper = game_scene.get("audio_helper")
		if audio_helper and audio_helper.has_method("reload_audio_settings"):
			audio_helper.reload_audio_settings()

func _apply_current_settings():
	_apply_audio_settings()
	_apply_video_settings()

func _save_current_settings():
	_save_audio_settings()
	_save_video_settings()

func _setup_confirmation_dialog():
	confirmation_dialog = ExitConfirmationDialog.new()
	confirmation_dialog.setup(self)

	confirmation_dialog.set_options_context()

func get_audio_helper():
	if is_in_game and game_scene and game_scene.has_method("get"):
		var game_audio_helper = game_scene.get("audio_helper")
		if game_audio_helper:
			return game_audio_helper
	
	return audio_manager

func return_to_menu():
	_copy_applied_to_current()
	_force_close_options()

func _configure_controls_for_gamepad():
	var regular_buttons = [reset_button, apply_button, close_button]
	for button in regular_buttons:
		if button and is_instance_valid(button):
			button.focus_mode = Control.FOCUS_ALL
			button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	if vsync_button and is_instance_valid(vsync_button):
		vsync_button.focus_mode = Control.FOCUS_ALL
		vsync_button.mouse_filter = Control.MOUSE_FILTER_PASS
		if "toggle_mode" in vsync_button:
			vsync_button.toggle_mode = true
	
	var all_sliders = [master_volume_slider, music_volume_slider, sfx_volume_slider]
	for slider in all_sliders:
		if slider and is_instance_valid(slider):
			slider.focus_mode = Control.FOCUS_ALL
			slider.mouse_filter = Control.MOUSE_FILTER_PASS
			slider.min_value = 0.0
			slider.max_value = 100.0
			slider.step = 1.0
			slider.allow_greater = false
			slider.allow_lesser = false

	var all_options = [window_mode_option, resolution_option]
	for option in all_options:
		if option and is_instance_valid(option):
			option.focus_mode = Control.FOCUS_ALL
			option.mouse_filter = Control.MOUSE_FILTER_PASS
			option.allow_reselect = false
			if option.get_popup():
				var popup = option.get_popup()
				popup.set_process_mode(Node.PROCESS_MODE_ALWAYS)

func _setup_ui_connections():
	if master_volume_slider:
		master_volume_slider.value_changed.connect(_on_master_volume_changed)
		master_volume_slider.focus_entered.connect(_on_control_focused.bind(master_volume_slider))
	if music_volume_slider:
		music_volume_slider.value_changed.connect(_on_music_volume_changed)
		music_volume_slider.focus_entered.connect(_on_control_focused.bind(music_volume_slider))
	if sfx_volume_slider:
		sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
		sfx_volume_slider.focus_entered.connect(_on_control_focused.bind(sfx_volume_slider))
	
	if window_mode_option:
		window_mode_option.item_selected.connect(_on_window_mode_changed)
		window_mode_option.focus_entered.connect(_on_control_focused.bind(window_mode_option))
	if resolution_option:
		resolution_option.item_selected.connect(_on_resolution_changed)
		resolution_option.focus_entered.connect(_on_control_focused.bind(resolution_option))
	if vsync_button:
		vsync_button.pressed.connect(_on_vsync_button_pressed)
		vsync_button.focus_entered.connect(_on_control_focused.bind(vsync_button))
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
		close_button.focus_entered.connect(_on_control_focused.bind(close_button))
	if apply_button:
		apply_button.pressed.connect(_on_apply_pressed)
		apply_button.focus_entered.connect(_on_control_focused.bind(apply_button))
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
		reset_button.focus_entered.connect(_on_control_focused.bind(reset_button))

func _on_vsync_button_pressed():
	vsync_enabled = !vsync_enabled
	_update_video_ui()
	
	_apply_vsync_setting()
	
	_play_ui_sound("ui_confirm")

func _setup_video_options():
	if window_mode_option:
		window_mode_option.clear()
		for mode_name in window_mode_names:
			window_mode_option.add_item(mode_name)
	
	if resolution_option:
		resolution_option.clear()
		for res_name in resolution_names:
			resolution_option.add_item(res_name)

func _setup_sliders():
	var sliders = [
		{"slider": master_volume_slider, "value": master_volume},
		{"slider": music_volume_slider, "value": music_volume},
		{"slider": sfx_volume_slider, "value": sfx_volume}
	]
	
	for slider_data in sliders:
		var slider = slider_data.slider
		if slider:
			slider.min_value = 0.0
			slider.max_value = 100.0
			slider.step = 1.0
			slider.value = clamp(slider_data.value * 100, 0, 100)
			slider.allow_greater = false
			slider.allow_lesser = false

func _collect_focusable_elements():
	focusable_elements.clear()
	
	var elements = [
		master_volume_slider,
		music_volume_slider,
		sfx_volume_slider,
		window_mode_option,
		resolution_option,
		vsync_button,
		reset_button,
		apply_button,
		close_button
	]
	
	for i in range(elements.size()):
		var element = elements[i]
		if element and is_instance_valid(element):
			focusable_elements.append(element)
			element.focus_mode = Control.FOCUS_ALL
			element.mouse_filter = Control.MOUSE_FILTER_PASS
			
			if element is OptionButton:
				element.set_process_input(true)
				if not element.item_selected.is_connected(_on_option_button_item_selected.bind(element)):
					element.item_selected.connect(_on_option_button_item_selected.bind(element))

func _on_option_button_item_selected(index: int, option_button: OptionButton):
	if is_in_game:
		_play_ui_sound("ui_confirm")
	
	if option_button == window_mode_option:
		_on_window_mode_changed(index)
	elif option_button == resolution_option:
		_on_resolution_changed(index)

func _setup_enhanced_navigation():
	var navigation_pairs = [
		[master_volume_slider, music_volume_slider],
		[music_volume_slider, sfx_volume_slider],
		[sfx_volume_slider, window_mode_option],
		[window_mode_option, resolution_option],
		[resolution_option, vsync_button],
		[vsync_button, reset_button],
		[reset_button, apply_button],
		[apply_button, close_button]
	]
	
	for i in range(navigation_pairs.size()):
		var current_pair = navigation_pairs[i]
		var current_element = current_pair[0]
		var next_element = current_pair[1]
		
		if current_element and next_element:
			current_element.focus_neighbor_bottom = next_element.get_path()
			next_element.focus_neighbor_top = current_element.get_path()
	
	if reset_button and apply_button:
		reset_button.focus_neighbor_right = apply_button.get_path()
		apply_button.focus_neighbor_left = reset_button.get_path()
		apply_button.focus_neighbor_right = close_button.get_path() if close_button else NodePath()
	
	if apply_button and close_button:
		close_button.focus_neighbor_left = apply_button.get_path()
	
	if close_button and master_volume_slider:
		close_button.focus_neighbor_bottom = master_volume_slider.get_path()
		master_volume_slider.focus_neighbor_top = close_button.get_path()

func _take_control():
	if is_in_game and game_scene:
		original_process_mode = game_scene.process_mode
		get_tree().paused = true
		game_scene.process_mode = Node.PROCESS_MODE_DISABLED
		_block_all_input()
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	set_process_unhandled_input(true)

func _block_all_input():
	if not is_in_game or not game_scene:
		return
	
	var input_blocker = ColorRect.new()
	input_blocker.name = "InputBlocker"
	input_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	input_blocker.color = Color.TRANSPARENT
	input_blocker.z_index = 50
	
	game_scene.add_child(input_blocker)
	input_blocked_nodes.append(input_blocker)
	original_input_modes.append(0)
	
	_recursive_block_input(game_scene)
	
	_block_card_interactions()

func _block_card_interactions():
	if not game_scene:
		return
	
	var hand_container = game_scene.get_node_or_null("UILayer/CenterArea/HandContainer")
	if hand_container:
		if hand_container.has_method("set_mouse_filter"):
			hand_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

		for card in hand_container.get_children():
			if card.has_method("set_mouse_filter"):
				input_blocked_nodes.append(card)
				original_input_modes.append(1 if card.mouse_filter == Control.MOUSE_FILTER_PASS else 0)
				card.mouse_filter = Control.MOUSE_FILTER_IGNORE

			if card.has_method("get_children"):
				for child in card.get_children():
					if child is Button:
						input_blocked_nodes.append(child)
						original_input_modes.append(1 if child.mouse_filter == Control.MOUSE_FILTER_PASS else 0)
						child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _release_control():
	if is_in_game and game_scene:
		game_scene.process_mode = original_process_mode
		_restore_input_in_background_nodes()
		get_tree().paused = false

func _block_input_in_background_nodes():
	input_blocked_nodes.clear()
	original_input_modes.clear()
	
	if game_scene:
		_recursive_block_input(game_scene)

func _recursive_block_input(node: Node):
	if node == self:
		return
	
	if node.has_method("set_process_input"):
		input_blocked_nodes.append(node)
		original_input_modes.append(1 if node.get("process_input") else 0)
		node.set_process_input(false)
		
		if node.has_method("set_process_unhandled_input"):
			node.set_process_unhandled_input(false)
		if node.has_method("set_process_unhandled_key_input"):
			node.set_process_unhandled_key_input(false)
	
	for child in node.get_children():
		_recursive_block_input(child)

func _restore_input_in_background_nodes():
	for i in range(input_blocked_nodes.size()):
		var node = input_blocked_nodes[i]
		if is_instance_valid(node):
			if node.name == "InputBlocker":
				node.queue_free()
				continue
				
			if i < original_input_modes.size():
				var should_process = original_input_modes[i] == 1
				if node.has_method("set_process_input"):
					node.set_process_input(should_process)
				if node.has_method("set_process_unhandled_input"):
					node.set_process_unhandled_input(should_process)
				if node.has_method("set_process_unhandled_key_input"):
					node.set_process_unhandled_key_input(should_process)
	
	input_blocked_nodes.clear()
	original_input_modes.clear()
	
	if is_in_game and game_scene:
		_restore_game_scene_mouse_filters()
		
func _restore_game_scene_mouse_filters():
	if not game_scene:
		return
		
	var hand_container = game_scene.get_node_or_null("UILayer/CenterArea/HandContainer")
	if hand_container:
		hand_container.mouse_filter = Control.MOUSE_FILTER_PASS
		for card in hand_container.get_children():
			if card.has_method("set_mouse_filter"):
				card.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var ui_layer = game_scene.get_node_or_null("UILayer")
	if ui_layer:
		var end_turn_button = ui_layer.get_node_or_null("BottomPanel/TurnButtonsContainer/EndTurnButton")
		if end_turn_button:
			end_turn_button.mouse_filter = Control.MOUSE_FILTER_PASS

		var controls_panel = ui_layer.get_node_or_null("ControlsPanel")
		if controls_panel:
			controls_panel.mouse_filter = Control.MOUSE_FILTER_PASS

func _focus_first_element():
	if focusable_elements.size() > 0:
		current_focus_index = 0
		var first_element = focusable_elements[0]
		if first_element and is_instance_valid(first_element):
			first_element.grab_focus()
			_ensure_element_visible(first_element)

func _on_control_focused(control: Control):
	if is_in_game:
		_play_ui_sound("ui_focus")
	
	_ensure_element_visible(control)
	
	if gamepad_mode:
		var index = focusable_elements.find(control)
		if index != -1:
			current_focus_index = index
		
		var tween = create_tween()
		tween.tween_property(control, "modulate", Color(1.2, 1.2, 1.0, 1.0), 0.1)
		
		_show_control_help(control)

func _show_control_help(control: Control):
	var help_text = ""
	
	if control is HSlider:
		help_text = "Left/Right: Adjust | A: Fine tune"
	elif control is OptionButton:
		help_text = "Left/Right: Change option"
	elif control is Button:
		help_text = "A: Press"

func _ensure_element_visible(element: Control):
	if not scroll_container or not element:
		return
	
	var scroll_rect = scroll_container.get_rect()
	var element_rect = element.get_global_rect()
	var container_rect = scroll_container.get_global_rect()
	
	var relative_pos = element_rect.position.y - container_rect.position.y
	var element_bottom = relative_pos + element_rect.size.y
	
	if relative_pos < scroll_container.scroll_vertical:
		var tween = create_tween()
		tween.tween_property(scroll_container, "scroll_vertical", int(relative_pos - 20), 0.3)
	
	elif element_bottom > scroll_container.scroll_vertical + scroll_rect.size.y:
		var target_scroll = int(element_bottom - scroll_rect.size.y + 20)
		var tween = create_tween()
		tween.tween_property(scroll_container, "scroll_vertical", target_scroll, 0.3)

func _detect_input_method(event: InputEvent):
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if not gamepad_mode:
			gamepad_mode = true
			last_input_was_gamepad = true
			CursorManager.set_gamepad_mode(true)
			_on_input_method_changed()
	elif event is InputEventMouse or event is InputEventKey:
		if gamepad_mode:
			gamepad_mode = false
			last_input_was_gamepad = false
			CursorManager.set_gamepad_mode(false)
			_on_input_method_changed()

func _on_input_method_changed():
	if gamepad_mode:
		if not get_viewport().gui_get_focus_owner():
			_focus_first_element()

func _input(event):
	if not visible:
		return
	
	if confirmation_dialog and confirmation_dialog.is_showing:
		confirmation_dialog.handle_input(event)
		get_viewport().set_input_as_handled()
		return
	
	_detect_input_method(event)
	
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("game_exit") or event.is_action_pressed("game_back"):
		hide_options()
		get_viewport().set_input_as_handled()
		return
	
	if gamepad_mode and (event.is_action_pressed("ui_accept") or event.is_action_pressed("game_select")):
		_handle_confirm_action()
		get_viewport().set_input_as_handled()
		return
	
	if gamepad_mode:
		_handle_gamepad_navigation(event)

func _handle_confirm_action():
	var focused_control = get_viewport().gui_get_focus_owner()
	if not focused_control:
		return
	
	if focused_control is OptionButton:
		_navigate_option_button(focused_control, 1)
	elif focused_control == vsync_button:
		_on_vsync_button_pressed()
	elif focused_control in [reset_button, apply_button, close_button]:
		if is_in_game:
			_play_ui_sound("ui_confirm")
		focused_control.emit_signal("pressed")
	elif focused_control in [master_volume_slider, music_volume_slider, sfx_volume_slider]:
		_navigate_slider(focused_control, 1)
	else:
		if is_in_game:
			_play_ui_sound("ui_confirm")
		
		if focused_control.has_method("_pressed"):
			focused_control._pressed()
		elif focused_control.has_signal("pressed"):
			focused_control.emit_signal("pressed")

func _handle_gamepad_navigation(event: InputEvent):
	if event.is_action_pressed("ui_up"):
		_navigate_focus(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_navigate_focus(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_handle_horizontal_navigation(-1, event)
	elif event.is_action_pressed("ui_right"):
		_handle_horizontal_navigation(1, event)

func _navigate_focus(direction: int):
	if focusable_elements.size() == 0:
		return
	
	var old_index = current_focus_index
	current_focus_index = (current_focus_index + direction) % focusable_elements.size()
	if current_focus_index < 0:
		current_focus_index = focusable_elements.size() - 1
	
	var target_element = focusable_elements[current_focus_index]
	if target_element and is_instance_valid(target_element):
		if target_element.focus_mode == Control.FOCUS_NONE:
			_navigate_focus(direction)
			return
		
		if target_element.disabled if target_element.has_method("set_disabled") else false:
			_navigate_focus(direction)
			return
		
		if not target_element.visible:
			_navigate_focus(direction)
			return
		
		target_element.grab_focus()
		_ensure_element_visible(target_element)
		_play_ui_sound("ui_focus")

func _handle_horizontal_navigation(direction: int, event: InputEvent):
	var focused = get_viewport().gui_get_focus_owner()
	
	if focused is HSlider:
		_navigate_slider(focused, direction)
		get_viewport().set_input_as_handled()
	elif focused is OptionButton:
		_navigate_option_button(focused, direction)
		get_viewport().set_input_as_handled()
	elif focused in [reset_button, apply_button, close_button]:
		_navigate_horizontal_buttons(direction)
		get_viewport().set_input_as_handled()

func _navigate_slider(slider: HSlider, direction: int):
	var current_value = slider.value
	var step_size = slider.step
	var new_value = current_value + (direction * step_size * 5.0)
	
	new_value = clamp(new_value, slider.min_value, slider.max_value)
	slider.value = new_value
	
	slider.emit_signal("value_changed", new_value)
	_play_ui_sound("ui_focus")

func _navigate_option_button(option_button: OptionButton, direction: int):
	var current_index = option_button.selected
	var item_count = option_button.get_item_count()
	
	if item_count <= 1:
		return
	
	var new_index = current_index + direction
	if new_index < 0:
		new_index = item_count - 1
	elif new_index >= item_count:
		new_index = 0
	
	option_button.selected = new_index
	option_button.emit_signal("item_selected", new_index)
	_play_ui_sound("ui_confirm")

func _force_option_button_selection(option_button: OptionButton):
	if not option_button:
		return
	
	_navigate_option_button(option_button, 1)

func _navigate_horizontal_buttons(direction: int):
	var focused = get_viewport().gui_get_focus_owner()
	var buttons = [reset_button, apply_button, close_button]
	var current_index = buttons.find(focused)
	
	if current_index != -1:
		var next_index = (current_index + direction) % buttons.size()
		if next_index < 0:
			next_index = buttons.size() - 1
		
		var next_button = buttons[next_index]
		if next_button and is_instance_valid(next_button):
			next_button.grab_focus()
			_play_ui_sound("ui_focus")

func _play_ui_sound(sound_name: String):
	var should_play_sound = _should_play_ui_sound(sound_name)
	
	if not should_play_sound:
		return
	
	if audio_manager and audio_manager.has_method("_play_sound"):
		var sound_map_for_audio_manager = {
			"ui_focus": "button_hover",
			"ui_confirm": "button_click", 
			"ui_alert": "notification",
			"menu_open": "button_click",
			"menu_close": "button_click",
			"notification": "notification"
		}
		
		var mapped_sound = sound_map_for_audio_manager.get(sound_name, "button_click")
		audio_manager._play_sound(mapped_sound)
		return
	
	var sound_map = {
		"ui_focus": "button_click",
		"ui_confirm": "button_click", 
		"ui_alert": "button_click",
		"menu_open": "button_click",
		"menu_close": "button_click",
		"notification": "notification"
	}
	
	var mapped_sound = sound_map.get(sound_name, "button_click")
	
	var temp_player = AudioStreamPlayer.new()
	temp_player.bus = "SFX"
	add_child(temp_player)
	
	var sound_path = "res://audio/ui/" + mapped_sound + ".wav"
	
	if ResourceLoader.exists(sound_path):
		temp_player.stream = load(sound_path)
		temp_player.play()
		
		temp_player.finished.connect(func(): temp_player.queue_free())
	else:
		temp_player.queue_free()

func _should_play_ui_sound(sound_name: String) -> bool:
	if audio_manager:
		return true

	match sound_name:
		"ui_focus":
			return false
		"ui_confirm":
			return true
		"ui_alert":
			return true
		"menu_open":
			return true
		"menu_close":
			return true
		"notification":
			return true
		_:
			return true

func _apply_audio_settings():
	if GlobalMusicManager:
		var final_music_volume = master_volume * music_volume
		GlobalMusicManager.set_master_music_volume(final_music_volume)
	
	if is_in_game and audio_manager:
		_apply_sfx_settings_to_audio_manager()
		if game_scene and game_scene.has_method("get") and game_scene.get("audio_helper"):
			var audio_helper = game_scene.get("audio_helper")
			if audio_helper and audio_helper.has_method("reload_audio_settings"):
				audio_helper.reload_audio_settings()
	else:
		_apply_sfx_settings_to_audio_buses()

func _apply_video_settings():
	if OS.get_name() == "Android" or OS.get_name() == "Web":
		return
	
	var window = get_window()
	if not window:
		return
	
	match current_window_mode:
		0:
			window.mode = Window.MODE_WINDOWED
		1:
			window.mode = Window.MODE_FULLSCREEN
		2:
			window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
		_:
			return
	
	if current_window_mode == 0:
		if current_resolution_index >= 0 and current_resolution_index < available_resolutions.size():
			var target_resolution = available_resolutions[current_resolution_index]
			window.size = target_resolution
			
			var screen_size = DisplayServer.screen_get_size()
			window.position = (screen_size - target_resolution) / 2
		else:
			print("Invalid resolution index: ", current_resolution_index)
	
	_apply_vsync_setting()
	
func _apply_vsync_setting():
	if OS.get_name() == "Android" or OS.get_name() == "Web":
		return
	
	var target_mode = DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	
	var current_mode = DisplayServer.window_get_vsync_mode()
	
	if current_mode != target_mode:
		DisplayServer.window_set_vsync_mode(target_mode)
		
		await get_tree().process_frame
		var new_mode = DisplayServer.window_get_vsync_mode()
		
		if new_mode == target_mode:
			print("VSync applied correctly: ", "ON" if vsync_enabled else "OFF")
		else:
			print("Warning: VSync could not be applied. Current mode: ", new_mode, " Expected: ", target_mode)
	else:
		print("VSync is already in the correct mode: ", "ON" if vsync_enabled else "OFF")

func _apply_sfx_settings_to_audio_manager():
	if not audio_manager:
		return
	
	var final_sfx_volume = master_volume * sfx_volume
	var volume_db = linear_to_db(final_sfx_volume) if final_sfx_volume > 0 else -80.0
	
	for pool_name in audio_manager.player_pools.keys():
		var pool = audio_manager.player_pools[pool_name]
		for player in pool:
			if player is AudioStreamPlayer:
				if not player.has_meta("original_volume_db"):
					player.set_meta("original_volume_db", player.volume_db)
				
				var original_volume = player.get_meta("original_volume_db")
				player.volume_db = original_volume + volume_db

func _apply_sfx_settings_to_audio_buses():
	var sfx_bus_idx = AudioServer.get_bus_index("SFX")
	if sfx_bus_idx != -1:
		var final_sfx_volume = master_volume * sfx_volume
		var volume_db = linear_to_db(final_sfx_volume) if final_sfx_volume > 0 else -80.0
		AudioServer.set_bus_volume_db(sfx_bus_idx, volume_db)

func _save_audio_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	
	config.save("user://audio_settings.cfg")

func _save_video_settings():
	if OS.get_name() == "Android" or OS.get_name() == "Web":
		return
	
	var config = ConfigFile.new()
	config.set_value("video", "window_mode", current_window_mode)
	config.set_value("video", "resolution_index", current_resolution_index)
	config.set_value("video", "vsync_enabled", vsync_enabled)
	
	config.save("user://video_settings.cfg")

func _update_all_ui():
	_update_audio_ui()
	_update_video_ui()

func _update_audio_ui():
	_update_volume_sliders()
	_update_volume_labels()

func _update_video_ui():
	if OS.get_name() == "Android" or OS.get_name() == "Web":
		return
	
	if window_mode_option:
		window_mode_option.selected = current_window_mode
	if resolution_option:
		resolution_option.selected = current_resolution_index
	if vsync_button:
		vsync_button.button_pressed = vsync_enabled
		vsync_button.text = "VSync: ON" if vsync_enabled else "VSync: OFF"

func _update_volume_sliders():
	if master_volume_slider:
		master_volume_slider.min_value = 0.0
		master_volume_slider.max_value = 100.0
		master_volume_slider.step = 1.0
		master_volume_slider.value = clamp(master_volume * 100, 0, 100)
	if music_volume_slider:
		music_volume_slider.min_value = 0.0
		music_volume_slider.max_value = 100.0
		music_volume_slider.step = 1.0
		music_volume_slider.value = clamp(music_volume * 100, 0, 100)
	if sfx_volume_slider:
		sfx_volume_slider.min_value = 0.0
		sfx_volume_slider.max_value = 100.0
		sfx_volume_slider.step = 1.0
		sfx_volume_slider.value = clamp(sfx_volume * 100, 0, 100)

func _update_volume_labels():
	if master_volume_label:
		master_volume_label.text = "Master Volume: " + str(int(master_volume * 100)) + "%"
	if music_volume_label:
		music_volume_label.text = "Music Volume: " + str(int(music_volume * 100)) + "%"
	if sfx_volume_label:
		sfx_volume_label.text = "SFX Volume: " + str(int(sfx_volume * 100)) + "%"

func _reset_to_defaults():
	_reset_audio_to_defaults()
	_reset_video_to_defaults()

func _reset_audio_to_defaults():
	master_volume = default_master_volume
	music_volume = default_music_volume
	sfx_volume = default_sfx_volume

func _reset_video_to_defaults():
	current_window_mode = default_window_mode
	current_resolution_index = default_resolution_index
	vsync_enabled = default_vsync

func _on_master_volume_changed(value: float):
	value = clamp(value, 0.0, 100.0)
	master_volume = value / 100.0
	_update_volume_labels()

func _on_music_volume_changed(value: float):
	value = clamp(value, 0.0, 100.0)
	music_volume = value / 100.0
	_update_volume_labels()

func _on_sfx_volume_changed(value: float):
	value = clamp(value, 0.0, 100.0)
	sfx_volume = value / 100.0
	_update_volume_labels()

func _on_window_mode_changed(index: int):
	current_window_mode = index

func _on_resolution_changed(index: int):
	current_resolution_index = index

func _on_close_pressed():
	hide_options()

func _on_reset_pressed():
	_reset_to_defaults()
	_update_all_ui()
	_play_ui_sound("ui_confirm")
