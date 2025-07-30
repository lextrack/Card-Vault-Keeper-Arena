extends Control

@onready var card_container = $CardContainer
@onready var particle_container = $ParticleContainer

const CARD_SCENE = preload("res://scenes/effects/FallingCard.tscn")
const PARTICLE_SCENE = preload("res://scenes/effects/Sparkle.tscn")

@export var max_cards: int = 12
@export var card_spawn_interval: float = 0.8
@export var max_particles: int = 8
@export var particle_spawn_interval: float = 1.5

var cards_spawned: Array[Node] = []
var particles_spawned: Array[Node] = []
var spawn_timer: Timer
var particle_timer: Timer

enum CardType {
	ATTACK,
	DEFENSE, 
	MAGIC,
	HEAL,
	SPECIAL,
	RARE
}

var card_colors = {
	CardType.ATTACK: Color(0.86, 0.15, 0.15, 1.0),
	CardType.DEFENSE: Color(0.15, 0.39, 0.93, 1.0),
	CardType.MAGIC: Color(0.49, 0.23, 0.93, 1.0),
	CardType.HEAL: Color(0.02, 0.59, 0.41, 1.0),
	CardType.SPECIAL: Color(0.85, 0.46, 0.04, 1.0),
	CardType.RARE: Color(0.86, 0.15, 0.47, 1.0) 
}

var card_symbols = {
	CardType.ATTACK: "⚔",
	CardType.DEFENSE: "🛡",
	CardType.MAGIC: "✨",
	CardType.HEAL: "❤",
	CardType.SPECIAL: "💎",
	CardType.RARE: "👑"
}

func _ready():
	setup_timers()
	start_spawning()

func setup_timers():
	spawn_timer = Timer.new()
	spawn_timer.wait_time = card_spawn_interval
	spawn_timer.timeout.connect(_spawn_card)
	spawn_timer.autostart = true
	add_child(spawn_timer)

	particle_timer = Timer.new()
	particle_timer.wait_time = particle_spawn_interval
	particle_timer.timeout.connect(_spawn_particle)
	particle_timer.autostart = true
	add_child(particle_timer)

func start_spawning():
	for i in range(5):
		await get_tree().create_timer(randf() * 2.0).timeout
		_spawn_card()

func _spawn_card():
	if cards_spawned.size() >= max_cards:
		return
	
	var card = CARD_SCENE.instantiate()
	if card:
		card.set_random_type()
		card.set_random_values()
		card.fall_duration = randf_range(6.0, 12.0)
		
		var screen_width = get_viewport().get_visible_rect().size.x
		var start_pos = Vector2(randf() * (screen_width - card.size.x), -100)
		
		card_container.add_child(card)
		card.start_falling_from_position(start_pos)
		cards_spawned.append(card)

		card.tree_exited.connect(_on_card_removed.bind(card))

func _spawn_particle():
	if particles_spawned.size() >= max_particles:
		return
	
	var particle = PARTICLE_SCENE.instantiate()
	if particle:
		particle.set_random_type()
		particle.life_duration = randf_range(2.0, 4.0)
		
		var screen_width = get_viewport().get_visible_rect().size.x
		var start_pos = Vector2(randf() * screen_width, get_viewport().get_visible_rect().size.y + 10)
		
		particle_container.add_child(particle)
		particle.start_from_position(start_pos)
		particles_spawned.append(particle)
		
		particle.tree_exited.connect(_on_particle_removed.bind(particle))

func create_falling_card() -> Control:
	var card = Control.new()
	card.size = Vector2(48, 67)
	
	var screen_width = get_viewport().get_visible_rect().size.x
	card.position.x = randf() * (screen_width + 100) - 50
	card.position.y = -100
	
	var card_bg = ColorRect.new()
	card_bg.size = card.size
	card_bg.anchors_preset = Control.PRESET_FULL_RECT
	
	var card_type = CardType.values()[randi() % CardType.size()]
	card_bg.color = card_colors[card_type]
	
	var border = ColorRect.new()
	border.size = Vector2(card.size.x - 4, card.size.y - 4)
	border.position = Vector2(2, 2)
	border.color = Color(1, 1, 1, 0.3)
	
	var symbol = Label.new()
	symbol.text = card_symbols[card_type]
	symbol.size = Vector2(30, 30)
	symbol.position = Vector2((card.size.x - 30) / 2, (card.size.y - 30) / 2)
	symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	symbol.add_theme_font_size_override("font_size", 20)

	var shine = ColorRect.new()
	shine.size = Vector2(card.size.x - 8, card.size.y - 8)
	shine.position = Vector2(4, 4)
	shine.color = Color(1, 1, 1, 0.1)
	
	card.add_child(card_bg)
	card.add_child(border)
	card.add_child(shine)
	card.add_child(symbol)
	
	animate_falling_card(card)
	
	return card

func animate_falling_card(card: Control):
	var screen_height = get_viewport().get_visible_rect().size.y
	var fall_duration = randf_range(6.0, 12.0)
	var rotation_amount = randf_range(-360, 360)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(card, "position:y", screen_height + 100, fall_duration)

	tween.tween_property(card, "rotation_degrees", rotation_amount, fall_duration)
	
	var horizontal_drift = randf_range(-50, 50)
	tween.tween_property(card, "position:x", card.position.x + horizontal_drift, fall_duration)
	
	card.modulate.a = 0.0
	tween.tween_property(card, "modulate:a", 0.8, 0.5)
	tween.tween_property(card, "modulate:a", 0.0, 1.0).set_delay(fall_duration - 1.0)
	
	await tween.finished
	if is_instance_valid(card):
		card.queue_free()

func create_sparkle_particle() -> Control:
	var particle = Control.new()
	particle.size = Vector2(4, 4)
	
	var screen_width = get_viewport().get_visible_rect().size.x
	particle.position.x = randf() * screen_width
	particle.position.y = get_viewport().get_visible_rect().size.y + 10

	var particle_bg = ColorRect.new()
	particle_bg.size = particle.size
	particle_bg.anchors_preset = Control.PRESET_FULL_RECT
	particle_bg.color = Color(0.39, 1.0, 0.85, 1.0)
	
	particle.add_child(particle_bg)
	
	animate_sparkle(particle)
	
	return particle

func animate_sparkle(particle: Control):
	var rise_duration = randf_range(2.0, 4.0)
	var screen_height = get_viewport().get_visible_rect().size.y
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(particle, "position:y", -20, rise_duration)

	var horizontal_drift = randf_range(-30, 30)
	tween.tween_property(particle, "position:x", particle.position.x + horizontal_drift, rise_duration)
	
	tween.tween_property(particle, "modulate:a", 0.0, 0.3)
	tween.tween_property(particle, "modulate:a", 1.0, 0.3).set_delay(0.3)
	tween.tween_property(particle, "modulate:a", 0.0, 0.3).set_delay(0.6)
	tween.tween_property(particle, "modulate:a", 1.0, 0.3).set_delay(0.9)
	tween.tween_property(particle, "modulate:a", 0.0, rise_duration - 1.2).set_delay(1.2)
	
	particle.scale = Vector2.ZERO
	tween.tween_property(particle, "scale", Vector2.ONE, 0.2)
	tween.tween_property(particle, "scale", Vector2.ZERO, 0.5).set_delay(rise_duration - 0.5)
	
	await tween.finished
	if is_instance_valid(particle):
		particle.queue_free()

func _on_card_removed(card: Node):
	if card in cards_spawned:
		cards_spawned.erase(card)

func _on_particle_removed(particle: Node):
	if particle in particles_spawned:
		particles_spawned.erase(particle)

func set_effect_intensity(intensity: float):
	intensity = clamp(intensity, 0.0, 1.0)
	
	spawn_timer.wait_time = lerp(2.0, 0.3, intensity)
	particle_timer.wait_time = lerp(3.0, 0.8, intensity)
	
	max_cards = int(lerp(5, 20, intensity))
	max_particles = int(lerp(3, 12, intensity))

func set_effect_active(active: bool):
	if spawn_timer:
		spawn_timer.paused = not active
	if particle_timer:
		particle_timer.paused = not active

func clear_all_effects():
	for card in cards_spawned:
		if is_instance_valid(card):
			card.queue_free()
	
	for particle in particles_spawned:
		if is_instance_valid(particle):
			particle.queue_free()
	
	cards_spawned.clear()
	particles_spawned.clear()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		clear_all_effects()
