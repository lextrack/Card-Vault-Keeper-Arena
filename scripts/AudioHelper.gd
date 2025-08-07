class_name AudioHelper
extends RefCounted

var audio_manager: AudioManager
var is_initialized: bool = false

var sfx_volume_multiplier: float = 1.0
var sfx_muted: bool = false

func setup(manager: AudioManager):
	audio_manager = manager
	is_initialized = audio_manager != null
	
	load_audio_settings()

func load_audio_settings():
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")
	
	if err == OK:
		var master_volume = config.get_value("audio", "master_volume", 1.0)
		var sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
		sfx_muted = config.get_value("audio", "sfx_muted", false)
		
		sfx_volume_multiplier = master_volume * sfx_volume
		
		print("AudioHelper: Configuración cargada - Volume: ", sfx_volume_multiplier, " Muted: ", sfx_muted)

		apply_volume_settings()
	else:
		print("AudioHelper: No se pudo cargar configuración, usando valores por defecto")

func reload_audio_settings():
	print("AudioHelper: Recargando configuración de audio...")
	load_audio_settings()

func apply_volume_settings():
	if not is_initialized:
		return
	
	var volume_db = linear_to_db(sfx_volume_multiplier) if sfx_volume_multiplier > 0 and not sfx_muted else -80.0
	
	for pool_name in audio_manager.player_pools.keys():
		var pool = audio_manager.player_pools[pool_name]
		for player in pool:
			if player is AudioStreamPlayer:
				if not player.has_meta("original_volume_db"):
					player.set_meta("original_volume_db", player.volume_db)
				
				var original_volume = player.get_meta("original_volume_db")
				player.volume_db = original_volume + volume_db

func update_sfx_settings(master_vol: float, sfx_vol: float, muted: bool):
	sfx_volume_multiplier = master_vol * sfx_vol
	sfx_muted = muted
	apply_volume_settings()
	print("AudioHelper: SFX settings updated - Volume: ", sfx_volume_multiplier, " Muted: ", sfx_muted)

func play_card_play_sound(card_type: String = "", damage: int = 0) -> bool:
	if not is_initialized or sfx_muted:
		return false
	return audio_manager.play_card_play_sound(card_type, damage)

func play_ai_card_play_sound(card_type: String = "") -> bool:
	if not is_initialized or sfx_muted:
		return false
	return audio_manager.play_ai_card_play_sound(card_type)

func play_ai_attack_sound() -> bool:
	if not is_initialized or sfx_muted:
		return false
	return audio_manager.play_ai_attack_sound()

func play_ai_heal_sound() -> bool:
	if not is_initialized or sfx_muted:
		return false
	return audio_manager.play_ai_heal_sound()

func play_ai_shield_sound() -> bool:
	if not is_initialized or sfx_muted:
		return false
	return audio_manager.play_ai_shield_sound()

func play_card_draw_sound() -> bool:
	if not is_initialized or sfx_muted:
		return false
	return audio_manager.play_card_draw_sound()

func play_card_hover_sound() -> bool:
	if not is_initialized or sfx_muted:
		return false
	return audio_manager.play_card_hover_sound()

func play_attack_sound(damage: int = 0) -> bool:
	if not is_initialized or sfx_muted:
		return false
	return audio_manager.play_attack_sound(damage)

func play_heal_sound() -> bool:
	if not is_initialized or sfx_muted:
		return false
	return audio_manager.play_heal_sound()

func play_shield_sound() -> bool:
	if not is_initialized or sfx_muted:
		return false
	return audio_manager.play_shield_sound()

func play_damage_sound(damage: int = 0) -> bool:
	if not is_initialized or sfx_muted:
		return false
	return audio_manager.play_damage_sound(damage)
	
func play_hybrid_sound() -> bool:
	if not is_initialized or sfx_muted:
		return false
	return audio_manager.play_hybrid_sound()

func play_ui_click_sound() -> bool:
	if not is_initialized or sfx_muted:
		return false
	return audio_manager.play_ui_click_sound()

func play_bonus_sound() -> bool:
	if not is_initialized or sfx_muted:
		return false
	return audio_manager.play_bonus_sound()

func play_turn_change_sound(is_player_turn: bool) -> bool:
	if not is_initialized or sfx_muted:
		return false
	return audio_manager.play_turn_change_sound(is_player_turn)

func play_win_sound() -> bool:
	if not is_initialized or sfx_muted:
		return false
	return audio_manager._play_sound("win")

func play_lose_sound() -> bool:
	if not is_initialized or sfx_muted:
		return false
	return audio_manager._play_sound("lose")
	
func stop_music_for_exit() -> bool:
	if not is_initialized:
		return false
	return audio_manager.stop_music()

func play_background_music() -> bool:
	if not is_initialized:
		return false
	return audio_manager.play_background_music()

func stop_background_music() -> bool:
	if not is_initialized:
		return false
	return audio_manager.stop_music()

func fade_music_out(duration: float = 1.0):
	if is_initialized:
		audio_manager.fade_music_out(duration)

func fade_music_in(duration: float = 1.0):
	if is_initialized:
		audio_manager.fade_music_in(duration)

func stop_all_audio():
	if is_initialized:
		audio_manager.stop_all_sounds()

func is_any_audio_playing() -> bool:
	if not is_initialized:
		return false
	return audio_manager.is_any_audio_playing()
