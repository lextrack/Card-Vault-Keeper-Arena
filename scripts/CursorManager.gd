extends Node

var gamepad_mode: bool = false
var cursor_hidden: bool = false

func _ready():
	pass

func set_gamepad_mode(enabled: bool):
	if gamepad_mode != enabled:
		gamepad_mode = enabled
		_update_cursor_visibility()

func _update_cursor_visibility():
	if gamepad_mode and not cursor_hidden:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		cursor_hidden = true
	elif not gamepad_mode and cursor_hidden:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		cursor_hidden = false

func show_cursor():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	cursor_hidden = false

func hide_cursor():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	cursor_hidden = true

func _input(event):
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event is InputEventJoypadButton and event.pressed:
			set_gamepad_mode(true)
	elif event is InputEventMouse:
		set_gamepad_mode(false)
