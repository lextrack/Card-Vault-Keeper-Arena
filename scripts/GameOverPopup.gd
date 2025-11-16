extends Control

signal new_game_requested
signal main_menu_requested

@onready var title_label = $CenterContainer/PopupPanel/BorderPanel/MarginContainer/VBoxMainContainer/TitleLabel
@onready var turns_label = $CenterContainer/PopupPanel/BorderPanel/MarginContainer/VBoxMainContainer/ContentHBox/StatsVBox/TurnsLabel
@onready var player_cards_label = $CenterContainer/PopupPanel/BorderPanel/MarginContainer/VBoxMainContainer/ContentHBox/StatsVBox/PlayerCardsLabel
@onready var damage_dealt_label = $CenterContainer/PopupPanel/BorderPanel/MarginContainer/VBoxMainContainer/ContentHBox/StatsVBox/DamageDealtLabel
@onready var damage_received_label = $CenterContainer/PopupPanel/BorderPanel/MarginContainer/VBoxMainContainer/ContentHBox/StatsVBox/DamageReceivedLabel
@onready var border_panel = $CenterContainer/PopupPanel/BorderPanel
@onready var popup_panel = $CenterContainer/PopupPanel
@onready var new_game_button = $CenterContainer/PopupPanel/BorderPanel/MarginContainer/VBoxMainContainer/ButtonsContainer/NewGameButton
@onready var main_menu_button = $CenterContainer/PopupPanel/BorderPanel/MarginContainer/VBoxMainContainer/ButtonsContainer/MainMenuButton
@onready var robot_slot = $CenterContainer/PopupPanel/BorderPanel/MarginContainer/VBoxMainContainer/ContentHBox/RobotContainer/RobotVBox/RobotSlot
@onready var dialogue_box = $CenterContainer/PopupPanel/BorderPanel/MarginContainer/VBoxMainContainer/ContentHBox/RobotContainer/RobotVBox/DialogueBox
@onready var dialogue_label = $CenterContainer/PopupPanel/BorderPanel/MarginContainer/VBoxMainContainer/ContentHBox/RobotContainer/RobotVBox/DialogueBox/MarginContainer/DialogueLabel

var robot_scene = preload("res://scenes/RobotHead.tscn")
var robot_instance = null
var last_victory_dialogue_index = -1
var last_defeat_dialogue_index = -1

var victory_dialogues = [
	"Well done, challenger!",
	"Impressive strategy!",
	"You've mastered the cards!",
	"Victory is yours!",
	"Excellent performance!"
]

var defeat_dialogues = [
	"Don't give up, try again!",
	"Every loss is a lesson!",
	"You'll get it next time!",
	"Keep practicing!",
	"Almost had it!"
]

func _ready():
	hide()
	modulate.a = 0
	_setup_button_navigation()
	_setup_robot()

func _setup_robot():
	robot_instance = robot_scene.instantiate()
	robot_slot.add_child(robot_instance)
	robot_instance.scale = Vector2(2.5, 2.5)

func _setup_button_navigation():
	if new_game_button and main_menu_button:
		new_game_button.focus_neighbor_right = main_menu_button.get_path()
		main_menu_button.focus_neighbor_left = new_game_button.get_path()
		
		new_game_button.focus_mode = Control.FOCUS_ALL
		main_menu_button.focus_mode = Control.FOCUS_ALL

func _get_random_dialogue(dialogues: Array, last_index: int) -> Dictionary:
	var index = randi_range(0, dialogues.size() - 1)
	
	if dialogues.size() > 1 and index == last_index:
		index = (index + 1) % dialogues.size()
	
	return {"text": dialogues[index], "index": index}

func show_game_over(won: bool, stats: Dictionary):
	if won:
		title_label.text = "VICTORY!"
		title_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
		border_panel.add_theme_stylebox_override("panel", border_panel.get_meta("_victory_style"))
		
		var dialogue_result = _get_random_dialogue(victory_dialogues, last_victory_dialogue_index)
		dialogue_label.text = dialogue_result.text
		last_victory_dialogue_index = dialogue_result.index
		_animate_robot_celebrate()
		_animate_title_victory()
		_animate_dialogue()
	else:
		title_label.text = "DEFEAT"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		border_panel.add_theme_stylebox_override("panel", border_panel.get_meta("_defeat_style"))
		
		var dialogue_result = _get_random_dialogue(defeat_dialogues, last_defeat_dialogue_index)
		dialogue_label.text = dialogue_result.text
		last_defeat_dialogue_index = dialogue_result.index
		_animate_robot_sad()
		_animate_title_defeat()
		_animate_dialogue()
	
	turns_label.text = "Turns played: " + str(stats.get("turns", 0))
	player_cards_label.text = "Cards played: " + str(stats.get("player_cards", 0))
	damage_dealt_label.text = "Damage dealt: " + str(stats.get("damage_dealt", 0))
	damage_received_label.text = "Damage taken: " + str(stats.get("damage_received", 0))
	
	show()
	_animate_in()
	
	await get_tree().create_timer(0.5).timeout
	if new_game_button:
		new_game_button.grab_focus()

func _animate_title_victory():
	title_label.scale = Vector2(0.5, 0.5)
	title_label.modulate.a = 0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(title_label, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.3)
	
	tween.chain().tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_IN_OUT)
	
	var bounce_tween = create_tween().set_loops(2)
	bounce_tween.tween_interval(0.5)
	bounce_tween.tween_property(title_label, "position:y", title_label.position.y - 10, 0.2)
	bounce_tween.tween_property(title_label, "position:y", title_label.position.y, 0.2)
	
	var color_tween = create_tween().set_loops()
	color_tween.tween_property(title_label, "modulate", Color(0.5, 1.5, 0.5), 0.8)
	color_tween.tween_property(title_label, "modulate", Color.WHITE, 0.8)

func _animate_title_defeat():
	title_label.scale = Vector2(1.5, 1.5)
	title_label.modulate.a = 0
	title_label.rotation = 0.3
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.3)
	tween.tween_property(title_label, "rotation", 0.0, 0.5).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(0.6).timeout
	
	var shake_tween = create_tween()
	for i in range(3):
		shake_tween.tween_property(title_label, "position:x", title_label.position.x + 5, 0.05)
		shake_tween.tween_property(title_label, "position:x", title_label.position.x - 5, 0.05)
	shake_tween.tween_property(title_label, "position:x", title_label.position.x, 0.05)

func _animate_dialogue():
	dialogue_box.modulate.a = 0
	dialogue_box.scale = Vector2(0.3, 0.3)
	dialogue_box.position.y = -30
	
	await get_tree().create_timer(0.6).timeout
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.3)
	tween.tween_property(dialogue_box, "scale", Vector2(1.1, 1.1), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(dialogue_box, "position:y", 0, 0.3).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	var scale_tween = create_tween()
	scale_tween.tween_property(dialogue_box, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_IN_OUT)
	
	await scale_tween.finished
	await get_tree().create_timer(1.0).timeout
	
	var bounce_tween = create_tween()
	bounce_tween.tween_property(dialogue_box, "scale", Vector2(1.05, 1.05), 0.2)
	bounce_tween.tween_property(dialogue_box, "scale", Vector2(1.0, 1.0), 0.2)

func _animate_robot_celebrate():
	await get_tree().create_timer(0.4).timeout
	if robot_instance:
		robot_instance.play_emotional_reaction("joy")
		
		await get_tree().create_timer(2.5).timeout
		if robot_instance:
			robot_instance.speak(dialogue_label.text)

func _animate_robot_sad():
	await get_tree().create_timer(0.4).timeout
	if robot_instance:
		robot_instance.play_emotional_reaction("sadness")
		
		await get_tree().create_timer(2.5).timeout
		if robot_instance:
			robot_instance.speak(dialogue_label.text)

func _animate_in():
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	popup_panel.scale = Vector2(0.8, 0.8)
	popup_panel.modulate.a = 0
	tween.tween_property(popup_panel, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(popup_panel, "modulate:a", 1.0, 0.3)

func _input(event):
	if not visible:
		return
	
	if event.is_action_pressed("game_select"):
		if new_game_button and new_game_button.has_focus():
			new_game_button.pressed.emit()
			get_viewport().set_input_as_handled()
		elif main_menu_button and main_menu_button.has_focus():
			main_menu_button.pressed.emit()
			get_viewport().set_input_as_handled()

func _on_new_game_button_pressed():
	new_game_requested.emit()

func _on_main_menu_button_pressed():
	main_menu_requested.emit()
