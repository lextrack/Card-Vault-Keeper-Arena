extends Control

@onready var title_label = $MainContainer/HeaderContainer/TitleLabel
@onready var credits_container = $MainContainer/CreditsContainer

var is_transitioning: bool = false
var entrance_tween: Tween

var gamepad_mode: bool = false
var last_input_was_gamepad: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	await handle_scene_entrance()

func handle_scene_entrance():
	await get_tree().process_frame
	
	if TransitionManager and TransitionManager.current_overlay:
		if (TransitionManager.current_overlay.has_method("is_ready") and 
			TransitionManager.current_overlay.is_ready() and 
			TransitionManager.current_overlay.has_method("is_covering") and
			TransitionManager.current_overlay.is_covering()):
			await TransitionManager.current_overlay.fade_out(0.8)
		else:
			play_entrance_animation()
	else:
		play_entrance_animation()

func play_entrance_animation():
	modulate.a = 0.0
	scale = Vector2(0.95, 0.95)
	
	entrance_tween = create_tween()
	entrance_tween.set_parallel(true)
	entrance_tween.tween_property(self, "modulate:a", 1.0, 0.8)
	entrance_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.6)
	
	await entrance_tween.finished
	animate_title()
	animate_sections()

func animate_title():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(title_label, "modulate", Color(1.2, 1.2, 0.9, 1.0), 3.0)
	tween.tween_property(title_label, "modulate", Color(1.0, 1.0, 0.8, 1.0), 3.0)

func animate_sections():
	var columns = [
		credits_container.get_child(0),
		credits_container.get_child(1),
		credits_container.get_child(2)
	]
	
	for i in range(columns.size()):
		var column = columns[i]
		if column:
			column.position.y += 20
			column.modulate.a = 0.0
			
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(column, "position:y", 0, 0.6)
			tween.tween_property(column, "modulate:a", 1.0, 0.8)
			
			await get_tree().create_timer(0.2).timeout

func _detect_input_method(event: InputEvent):
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if not gamepad_mode:
			gamepad_mode = true
			last_input_was_gamepad = true
	elif event is InputEventMouse or event is InputEventKey:
		if gamepad_mode:
			gamepad_mode = false
			last_input_was_gamepad = false

func _input(event):
	if is_transitioning:
		return
	
	_detect_input_method(event)
	
	if (event.is_action_pressed("ui_cancel") or 
		event.is_action_pressed("ui_accept") or 
		event.is_action_pressed("game_back") or
		event.is_action_pressed("game_exit")):
		
		_on_exit_credits()
		get_viewport().set_input_as_handled()

func _on_exit_credits():
	if is_transitioning:
		return
	
	is_transitioning = true
	
	TransitionManager.fade_to_main_menu(1.0)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_on_exit_credits()

func hide_credits():
	_on_exit_credits()
