class_name AudioManager
extends Node

@onready var card_play_player = $CardSounds/CardPlayPlayer
@onready var card_draw_player = $CardSounds/CardDrawPlayer
@onready var card_hover_player = $CardSounds/CardHoverPlayer

@onready var attack_player = $CombatSounds/AttackPlayer
@onready var heal_player = $CombatSounds/HealPlayer
@onready var shield_player = $CombatSounds/ShieldPlayer
@onready var damage_player = $CombatSounds/DamagePlayer
@onready var hybrid_player = $CombatSounds/HybridPlayer
@onready var joker_player = $CombatSounds/JokerPlayer

@onready var ai_attack_player = $AISounds/AIAttackPlayer
@onready var ai_heal_player = $AISounds/AIHealPlayer
@onready var ai_shield_player = $AISounds/AIShieldPlayer
@onready var ai_card_play_player = $AISounds/AICardPlayPlayer

@onready var turn_change_player = $GameSounds/TurnChangePlayer
@onready var win_player = $GameSounds/WinPlayer
@onready var lose_player = $GameSounds/LosePlayer
@onready var bonus_player = $GameSounds/BonusPlayer
@onready var music_player = $GameSounds/MusicPlayer

@onready var ui_click_player = $UISounds/UIClickPlayer
@onready var ui_hover_player = $UISounds/UIHoverPlayer

var player_pools: Dictionary = {}

func _ready():
	_assign_base_players_to_sfx_bus()
	_create_player_pools()

func _assign_base_players_to_sfx_bus():
	var base_players = [
		card_play_player, card_draw_player, card_hover_player, hybrid_player,
		joker_player, attack_player, heal_player, shield_player, damage_player,
		ai_attack_player, ai_heal_player, ai_shield_player, ai_card_play_player,
		turn_change_player, win_player, lose_player,
		bonus_player, ui_click_player, ui_hover_player
	]
	
	for player in base_players:
		if player:
			player.bus = "SFX"

func _create_player_pools():
	_create_pool("card_play", card_play_player, 3)
	_create_pool("card_draw", card_draw_player, 3)
	_create_pool("card_hover", card_hover_player, 6)
	_create_pool("attack", attack_player, 2)
	_create_pool("heal", heal_player, 2)
	_create_pool("shield", shield_player, 2)
	_create_pool("damage", damage_player, 4)
	_create_pool("hybrid", hybrid_player, 2)
	_create_pool("joker_play", joker_player, 1)
	
	_create_pool("ai_attack", ai_attack_player, 2)
	_create_pool("ai_heal", ai_heal_player, 2)
	_create_pool("ai_shield", ai_shield_player, 2)
	_create_pool("ai_card_play", ai_card_play_player, 2)
	
	_create_pool("turn_change", turn_change_player, 2)
	_create_pool("win", win_player, 1)
	_create_pool("lose", lose_player, 1)
	_create_pool("bonus", bonus_player, 2)
	
	_create_pool("ui_click", ui_click_player, 5)
	_create_pool("ui_hover", ui_hover_player, 2)
	_create_pool("button_click", ui_click_player, 5)
	_create_pool("button_hover", ui_hover_player, 5)

func _create_pool(pool_name: String, base_player: AudioStreamPlayer, pool_size: int):
	if not base_player or not base_player.stream:
		return
	
	var pool = []
	for i in range(pool_size):
		var player = AudioStreamPlayer.new()
		player.stream = base_player.stream
		player.volume_db = base_player.volume_db
		player.pitch_scale = base_player.pitch_scale
		player.bus = "SFX"
		add_child(player)
		pool.append(player)
	
	player_pools[pool_name] = pool

func _get_available_player(pool_name: String) -> AudioStreamPlayer:
	if not player_pools.has(pool_name):
		return null
	
	var pool = player_pools[pool_name]
	for player in pool:
		if not player.playing:
			return player
	
	return pool[0]

func play_card_play_sound(card_type: String = "", damage: int = 0) -> bool:
	match card_type:
		"attack":
			return play_attack_sound()
		"heal":
			return play_heal_sound()
		"shield":
			return play_shield_sound()
		"hybrid":
			play_hybrid_sound()
			return true
		_:
			return _play_sound("card_play")

func play_ai_card_play_sound(card_type: String = "") -> bool:
	match card_type:
		"attack":
			return play_ai_attack_sound()
		"heal":
			return play_ai_heal_sound()
		"shield":
			return play_ai_shield_sound()
		"hybrid":
			play_hybrid_sound()
			return true
		_:
			return _play_sound("ai_card_play")

func play_hybrid_sound():
	get_tree().create_timer(0.2).timeout.connect(_play_delayed_hybrid)

func _play_delayed_hybrid():
	_play_sound("hybrid")
	
func play_joker_sound() -> bool:
	return _play_sound("joker_play")

func play_ai_attack_sound() -> bool:
	return _play_sound("ai_attack")

func play_ai_heal_sound() -> bool:
	return _play_sound("ai_heal")

func play_ai_shield_sound() -> bool:
	return _play_sound("ai_shield")

func play_card_draw_sound() -> bool:
	return _play_sound("card_draw")

func play_card_hover_sound() -> bool:
	return _play_sound("card_hover")

func play_attack_sound(damage: int = 0) -> bool:
	return _play_sound("attack")

func play_heal_sound() -> bool:
	return _play_sound("heal")

func play_shield_sound() -> bool:
	return _play_sound("shield")

func play_damage_sound(damage: int = 0) -> bool:
	return _play_sound("damage")

func play_ui_click_sound() -> bool:
	return _play_sound("ui_click")

func play_ui_hover_sound() -> bool:
	return _play_sound("ui_hover")

func play_button_click_sound() -> bool:
	return _play_sound("button_click")

func play_button_hover_sound() -> bool:
	return _play_sound("button_hover")

func play_bonus_sound() -> bool:
	return _play_sound("bonus")

func play_turn_change_sound(is_player_turn: bool) -> bool:
	return _play_sound("turn_change")

func play_win_sound() -> bool:
	return _play_sound("win")

func play_lose_sound() -> bool:
	return _play_sound("lose")

func play_deck_shuffle_sound() -> bool:
	return _play_sound("deck_shuffle")

func _play_sound(sound_name: String) -> bool:
	var player = _get_available_player(sound_name)
	if player:
		player.play()
		return true
	return false

func play_background_music() -> bool:
	if music_player and music_player.stream:
		return true
	return false
	
func stop_music_for_game_end() -> bool:
	if music_player:
		music_player.stop()
		return true
	return false

func stop_music() -> bool:
	if music_player:
		music_player.stop()
		return true
	return false

func fade_music_out(duration: float = 1.0):
	if not music_player:
		return
	
	var original_volume = music_player.volume_db
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -60.0, duration)
	await tween.finished
	music_player.stop()
	music_player.volume_db = original_volume

func fade_music_in(duration: float = 1.0):
	if not music_player or not music_player.stream:
		return
	
	var target_volume = music_player.volume_db
	music_player.volume_db = -60.0
	music_player.play()
	
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", target_volume, duration)

func stop_all_sounds():
	for pool_name in player_pools.keys():
		var pool = player_pools[pool_name]
		for player in pool:
			if player.playing:
				player.stop()

func is_any_audio_playing() -> bool:
	for pool_name in player_pools.keys():
		var pool = player_pools[pool_name]
		for player in pool:
			if player.playing:
				return true
	return music_player.playing if music_player else false
