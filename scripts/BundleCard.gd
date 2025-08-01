class_name BundleCard
extends Control

@onready var bundle_name = $CardPanel/VBoxContainer/HeaderContainer/BundleName
@onready var price_container = $CardPanel/VBoxContainer/HeaderContainer/PriceContainer
@onready var price_label = $CardPanel/VBoxContainer/HeaderContainer/PriceContainer/PriceLabel
@onready var status_icon = $CardPanel/VBoxContainer/StatusContainer/StatusIcon
@onready var status_label = $CardPanel/VBoxContainer/StatusContainer/StatusLabel
@onready var card_icons_container = $CardPanel/VBoxContainer/PreviewContainer/CardIconsContainer
@onready var rarity_info = $CardPanel/VBoxContainer/PreviewContainer/RarityInfo
@onready var description_label = $CardPanel/VBoxContainer/DescriptionContainer/DescriptionLabel
@onready var requirement_label = $CardPanel/VBoxContainer/RequirementContainer/RequirementLabel
@onready var progress_bar = $CardPanel/VBoxContainer/RequirementContainer/ProgressContainer/ProgressBar
@onready var progress_label = $CardPanel/VBoxContainer/RequirementContainer/ProgressContainer/ProgressLabel
@onready var unlock_button = $CardPanel/VBoxContainer/ActionContainer/UnlockButton
@onready var mystery_text = $CardPanel/VBoxContainer/PreviewContainer/MysteryText

@onready var background_gradient = $CardPanel/BackgroundGradient
@onready var border_highlight = $CardPanel/BorderHighlight
@onready var card_shadow = $CardPanel/CardShadow

var bundle_info: Dictionary = {}
var original_scale: Vector2
var hover_tween: Tween
var glow_tween: Tween
var setup_complete: bool = false

signal bundle_unlock_requested(bundle_id: String)
signal bundle_hovered(bundle_info: Dictionary)
signal bundle_unhovered

func _ready():
	original_scale = scale
	setup_complete = false
	
	if not _validate_nodes():
		push_error("BundleCard: Missing required nodes")
		return
	
	setup_interactions()
	setup_animations()
	
	call_deferred("_mark_setup_complete")

func _mark_setup_complete():
	setup_complete = true
	if not bundle_info.is_empty():
		update_display()

func _validate_nodes() -> bool:
	var required_nodes = [
		bundle_name, status_icon, status_label, card_icons_container,
		rarity_info, description_label, requirement_label, 
		progress_bar, progress_label, unlock_button,
		background_gradient, border_highlight, card_shadow
	]
	
	for node in required_nodes:
		if not node:
			push_error("BundleCard: Missing node: " + str(node))
			return false
	
	return true

func setup_interactions():
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	_configure_mouse_filters_recursive(self)
	
	if unlock_button:
		unlock_button.pressed.connect(_on_unlock_pressed)
		unlock_button.mouse_entered.connect(_on_button_hover)
		unlock_button.mouse_exited.connect(_on_button_unhover)
		unlock_button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	

func _configure_mouse_filters_recursive(node: Node):
	for child in node.get_children():
		if child.has_method("set") and "mouse_filter" in child:
			if child is Button:
				child.mouse_filter = Control.MOUSE_FILTER_STOP
			else:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		_configure_mouse_filters_recursive(child)

func setup_animations():
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	
	var entrance_tween = create_tween()
	entrance_tween.set_parallel(true)
	entrance_tween.tween_property(self, "modulate:a", 1.0, 0.4)
	entrance_tween.tween_property(self, "scale", original_scale, 0.3)

func setup_bundle(info: Dictionary):
	bundle_info = info
	
	if setup_complete:
		update_display()
	elif not bundle_info.is_empty():
		call_deferred("_try_update_display")

func _try_update_display():
	await get_tree().process_frame
	if setup_complete:
		update_display()
	else:
		await get_tree().create_timer(0.1).timeout
		if setup_complete:
			update_display()

func update_display():
	if bundle_info.is_empty():
		print("BundleCard: No bundle info provided")
		return
	
	if not _validate_nodes():
		print("BundleCard: Nodes not ready, retrying...")
		call_deferred("update_display")
		return
	
	_safe_set_text(bundle_name, bundle_info.get("name", "Unknown Bundle"))
	_safe_set_text(description_label, bundle_info.get("description", "No description"))
	_safe_set_text(requirement_label, bundle_info.get("requirement_text", "No requirements"))
	
	var is_unlocked = bundle_info.get("unlocked", false)
	var can_unlock = bundle_info.get("can_unlock", false)
	
	update_status_display(is_unlocked, can_unlock)
	update_progress_display()
	update_visual_style(is_unlocked, can_unlock)
	update_rarity_info_display(is_unlocked)
	update_card_preview()

func update_rarity_info_display(is_unlocked: bool):
	if not rarity_info:
		print("BundleCard: rarity_info node not found")
		return
	
	var rarity_text = ""
	var rarity_color = Color.WHITE
	
	if is_unlocked:
		var bundle_cards = bundle_info.get("cards", [])
		if bundle_cards.size() > 0:
			rarity_text = _generate_rarity_text_from_cards(bundle_cards)
			rarity_color = Color(0.9, 1, 0.9, 1)
		else:
			rarity_text = bundle_info.get("rarity_info", "Unknown cards")
			rarity_color = Color(0.9, 1, 0.9, 1)
	else:
		rarity_text = "??? Mystery Cards ???"
		rarity_color = Color(0.7, 0.7, 0.8, 0.8)
		
		if mystery_text:
			mystery_text.visible = true
			mystery_text.modulate = rarity_color
	
	rarity_info.text = rarity_text
	rarity_info.modulate = rarity_color
	
	if OS.is_debug_build():
		print("🎴 Bundle ", bundle_info.get("name", ""), " rarity info: ", rarity_text)

func _generate_rarity_text_from_cards(card_names: Array) -> String:
	if not UnlockManagers:
		return bundle_info.get("rarity_info", "Unknown")
	
	var rarity_counts = {"common": 0, "uncommon": 0, "rare": 0, "epic": 0}
	var type_counts = {"attack": 0, "heal": 0, "shield": 0, "hybrid": 0}
	
	for card_name in card_names:
		var card_template = CardDatabase.find_card_by_name(card_name)
		if not card_template.is_empty():
			var rarity = card_template.get("rarity", RaritySystem.Rarity.COMMON)
			var rarity_str = RaritySystem.get_rarity_string(rarity)
			var card_type = card_template.get("type", "attack")
			
			if rarity_counts.has(rarity_str):
				rarity_counts[rarity_str] += 1
			
			if type_counts.has(card_type):
				type_counts[card_type] += 1
	
	var rarity_parts = []
	
	if rarity_counts.epic > 0:
		rarity_parts.append(str(rarity_counts.epic) + " Epic")
	
	if rarity_counts.rare > 0:
		rarity_parts.append(str(rarity_counts.rare) + " Rare")
	
	if rarity_counts.uncommon > 0:
		rarity_parts.append(str(rarity_counts.uncommon) + " Uncommon")
	
	if rarity_counts.common > 0 and rarity_parts.size() == 0:
		rarity_parts.append(str(rarity_counts.common) + " Common")
	
	var result_text = ""
	if rarity_parts.size() > 0:
		result_text = "Contains: " + ", ".join(rarity_parts)
	else:
		result_text = bundle_info.get("rarity_info", "Mixed cards")
	
	return result_text

func update_card_preview():
	if not card_icons_container:
		return
	
	for child in card_icons_container.get_children():
		child.queue_free()
	
	var is_unlocked = bundle_info.get("unlocked", false)
	
	if mystery_text:
		mystery_text.visible = not is_unlocked
	
	if is_unlocked:
		var bundle_cards = bundle_info.get("cards", [])
		
		if bundle_cards.size() > 0:
			var cards_list = create_cards_list(bundle_cards)
			card_icons_container.add_child(cards_list)
		else:
			var placeholder = Label.new()
			placeholder.text = "Cards unlocked!"
			placeholder.modulate = Color(0.7, 1.0, 0.7, 1.0)
			placeholder.add_theme_font_size_override("font_size", 12)
			placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			card_icons_container.add_child(placeholder)

func create_cards_list(card_names: Array) -> Control:
	var scroll_container = ScrollContainer.new()
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	
	var max_cards_to_show = min(card_names.size(), 3)
	
	for i in range(max_cards_to_show):
		var card_name = card_names[i]
		var card_template = CardDatabase.find_card_by_name(card_name)
		
		if not card_template.is_empty():
			var card_item = create_card_list_item(card_template)
			vbox.add_child(card_item)
	
	if card_names.size() > max_cards_to_show:
		var more_item = Label.new()
		more_item.text = "+" + str(card_names.size() - max_cards_to_show) + " more cards..."
		more_item.modulate = Color(0.7, 0.7, 0.8, 0.8)
		more_item.add_theme_font_size_override("font_size", 12)
		more_item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		more_item.custom_minimum_size = Vector2(0, 20)
		vbox.add_child(more_item)
	
	scroll_container.add_child(vbox)
	return scroll_container

func create_card_list_item(card_template: Dictionary) -> Control:
	var item_container = HBoxContainer.new()
	item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_container.add_theme_constant_override("separation", 6)
	item_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var type_icon = Label.new()
	type_icon.custom_minimum_size = Vector2(20, 20)
	type_icon.add_theme_font_size_override("font_size", 16)
	
	var card_type = card_template.get("type", "attack")
	match card_type:
		"attack":
			type_icon.text = "⚔️"
			type_icon.modulate = Color(1.1, 0.4, 0.4, 1.0)
		"heal":
			type_icon.text = "💚"
			type_icon.modulate = Color(0.4, 1.1, 0.4, 1.0)
		"shield":
			type_icon.text = "🛡️"
			type_icon.modulate = Color(0.4, 0.6, 1.1, 1.0)
		"hybrid":
			type_icon.text = "✨"
			type_icon.modulate = Color(1.1, 0.8, 0.3, 1.0)
		_:
			type_icon.text = "❓"
			type_icon.modulate = Color(0.7, 0.7, 0.7, 1.0)
	
	type_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var name_label = Label.new()
	name_label.text = card_template.get("name", "Unknown")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var rarity = card_template.get("rarity", RaritySystem.Rarity.COMMON)
	match rarity:
		RaritySystem.Rarity.COMMON:
			name_label.modulate = Color(0.95, 0.95, 0.95, 1.0)
		RaritySystem.Rarity.UNCOMMON:
			name_label.modulate = Color(0.7, 1.2, 0.9, 1.0)
		RaritySystem.Rarity.RARE:
			name_label.modulate = Color(0.8, 0.9, 1.4, 1.0)
		RaritySystem.Rarity.EPIC:
			name_label.modulate = Color(1.4, 1.0, 1.6, 1.0)
	
	var stats_label = Label.new()
	var stats_text = ""
	var stats_color = Color.WHITE
	
	match card_type:
		"attack":
			stats_text = str(card_template.get("damage", 0))
			stats_color = Color(1.1, 0.5, 0.5, 1.0)
		"heal":
			stats_text = str(card_template.get("heal", 0))
			stats_color = Color(0.5, 1.1, 0.5, 1.0)
		"shield":
			stats_text = str(card_template.get("shield", 0))
			stats_color = Color(0.5, 0.7, 1.1, 1.0)
		"hybrid":
			var parts = []
			if card_template.get("damage", 0) > 0:
				parts.append(str(card_template.get("damage", 0)))
			if card_template.get("heal", 0) > 0:
				parts.append(str(card_template.get("heal", 0)))
			if card_template.get("shield", 0) > 0:
				parts.append(str(card_template.get("shield", 0)))
			stats_text = "/".join(parts)
			stats_color = Color(0.9, 0.8, 0.6, 1.0)
	
	stats_label.text = stats_text
	stats_label.add_theme_font_size_override("font_size", 12)
	stats_label.modulate = stats_color
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_label.custom_minimum_size = Vector2(35, 0)
	
	var background = ColorRect.new()
	background.color = Color(0.12, 0.12, 0.18, 0.4)
	background.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	background.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_container.add_child(background)
	background.z_index = -1
	
	item_container.add_child(type_icon)
	item_container.add_child(name_label)
	item_container.add_child(stats_label)
	
	return item_container

func _safe_set_text(node: Node, text: String):
	if node and node.has_method("set_text"):
		node.text = text
	elif node and "text" in node:
		node.text = text
	else:
		push_warning("BundleCard: Cannot set text on node: " + str(node))

func _safe_set_visible(node: Node, visible: bool):
	if node:
		node.visible = visible

func _safe_set_color(node: Node, color: Color):
	if node and "color" in node:
		node.color = color
	elif node and "modulate" in node:
		node.modulate = color

func update_status_display(is_unlocked: bool, can_unlock: bool):
	if not status_icon or not status_label or not unlock_button:
		return
	
	if is_unlocked:
		_safe_set_text(status_icon, "✅")
		_safe_set_text(status_label, "UNLOCKED")
		status_label.modulate = Color(0.4, 1, 0.4, 1)
		_safe_set_visible(unlock_button, false)
	elif can_unlock:
		_safe_set_text(status_icon, "🔓")
		_safe_set_text(status_label, "READY TO UNLOCK")
		status_label.modulate = Color(1, 0.8, 0.2, 1)
		_safe_set_visible(unlock_button, true)
		unlock_button.disabled = false
		_safe_set_text(unlock_button, "🎁 UNLOCK NOW")
	else:
		_safe_set_text(status_icon, "🔒")
		_safe_set_text(status_label, "LOCKED")
		status_label.modulate = Color(0.7, 0.7, 0.7, 1)
		_safe_set_visible(unlock_button, false)

func update_progress_display():
	if not progress_bar or not progress_label:
		return
	
	var progress = bundle_info.get("progress", 0)
	var requirement_value = 1
	var requirement_type = bundle_info.get("requirement_type", "")
	
	match requirement_type:
		"free":
			_safe_set_visible(progress_bar, false)
			_safe_set_visible(progress_label, false)
			return
		"wins_normal", "wins_hard", "wins_expert":
			requirement_value = bundle_info.get("requirement_value", 5)
		"survive_turns":
			requirement_value = bundle_info.get("requirement_value", 15)
		"hybrid_cards_played":
			requirement_value = bundle_info.get("requirement_value", 25)
		"speed_win_hard", "perfect_victory", "low_hp_victory":
			requirement_value = 1
		"all_bundles":
			requirement_value = bundle_info.get("requirement_value", 6)
		"games_completed":
			requirement_value = bundle_info.get("requirement_value", 3)
		"total_wins":
			requirement_value = bundle_info.get("requirement_value", 50)
		_:
			requirement_value = bundle_info.get("requirement_value", 1)
	
	var displayed_progress = min(progress, requirement_value)
	
	progress_bar.max_value = requirement_value
	progress_bar.value = displayed_progress
	
	var progress_text = str(displayed_progress) + "/" + str(requirement_value)
	_safe_set_text(progress_label, progress_text)
	
	var progress_ratio = float(displayed_progress) / float(requirement_value)
	if progress_ratio >= 1.0:
		progress_bar.modulate = Color(0.4, 1, 0.4, 1)
	elif progress_ratio >= 0.7:
		progress_bar.modulate = Color(1, 0.8, 0.2, 1)
	elif progress_ratio >= 0.3:
		progress_bar.modulate = Color(1, 1, 0.4, 1)
	else:
		progress_bar.modulate = Color(0.8, 0.8, 0.8, 1)

func update_visual_style(is_unlocked: bool, can_unlock: bool):
	if not background_gradient or not border_highlight:
		return
	
	if is_unlocked:
		_safe_set_color(background_gradient, Color(0.1, 0.25, 0.15, 0.9))
		_safe_set_color(border_highlight, Color(0.2, 0.8, 0.4, 0.8))
		start_unlocked_glow()
	elif can_unlock:
		_safe_set_color(background_gradient, Color(0.25, 0.2, 0.1, 0.9))
		_safe_set_color(border_highlight, Color(1, 0.8, 0.2, 0.8))
		start_ready_glow()
	else:
		_safe_set_color(background_gradient, Color(0.15, 0.15, 0.25, 0.9))
		_safe_set_color(border_highlight, Color(0.3, 0.3, 0.4, 0.8))
		stop_glow()

func start_unlocked_glow():
	if not border_highlight:
		return
		
	if glow_tween:
		glow_tween.kill()
	
	glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(border_highlight, "modulate", Color(1.2, 1.4, 1.2, 1.0), 1.0)
	glow_tween.tween_property(border_highlight, "modulate", Color(0.8, 1.0, 0.8, 1.0), 1.0)

func start_ready_glow():
	if not border_highlight:
		return
		
	if glow_tween:
		glow_tween.kill()
	
	glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(border_highlight, "modulate", Color(1.4, 1.2, 0.8, 1.0), 0.8)
	glow_tween.tween_property(border_highlight, "modulate", Color(1.0, 0.9, 0.6, 1.0), 0.8)

func stop_glow():
	if glow_tween:
		glow_tween.kill()
	if border_highlight:
		border_highlight.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_mouse_entered():
	bundle_hovered.emit(bundle_info)
	
	if not card_shadow:
		return
	
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	hover_tween.tween_property(self, "scale", original_scale * 1.02, 0.15)
	hover_tween.tween_property(card_shadow, "offset_left", 6, 0.15)
	hover_tween.tween_property(card_shadow, "offset_top", 6, 0.15)
	hover_tween.tween_property(card_shadow, "color:a", 0.6, 0.15)

func _on_mouse_exited():
	bundle_unhovered.emit()
	
	if not card_shadow:
		return
	
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	hover_tween.tween_property(self, "scale", original_scale, 0.15)
	hover_tween.tween_property(card_shadow, "offset_left", 4, 0.15)
	hover_tween.tween_property(card_shadow, "offset_top", 4, 0.15)
	hover_tween.tween_property(card_shadow, "color:a", 0.4, 0.15)

func _on_button_hover():
	if not unlock_button:
		return
		
	var button_tween = create_tween()
	button_tween.tween_property(unlock_button, "scale", Vector2(1.1, 1.1), 0.1)

func _on_button_unhover():
	if not unlock_button:
		return
		
	var button_tween = create_tween()
	button_tween.tween_property(unlock_button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_unlock_pressed():
	if bundle_info.is_empty():
		return
	
	var bundle_id = bundle_info.get("id", "")
	if bundle_id != "":
		bundle_unlock_requested.emit(bundle_id)
		play_unlock_animation()

func play_unlock_animation():
	if unlock_button:
		unlock_button.disabled = true
	
	var celebrate_tween = create_tween()
	celebrate_tween.set_parallel(true)
	
	celebrate_tween.tween_property(self, "scale", original_scale * 1.15, 0.2)
	celebrate_tween.tween_property(self, "scale", original_scale, 0.3)
	
	celebrate_tween.tween_property(self, "modulate", Color(1.3, 1.2, 1.1, 1.0), 0.2)
	celebrate_tween.tween_property(self, "modulate", Color.WHITE, 0.4)
	
	await celebrate_tween.finished

	await get_tree().create_timer(0.5).timeout
	update_display()

func get_bundle_id() -> String:
	return bundle_info.get("id", "")

func is_unlocked() -> bool:
	return bundle_info.get("unlocked", false)

func can_unlock() -> bool:
	return bundle_info.get("can_unlock", false)

func force_refresh():
	setup_complete = true
	update_display()

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if hover_tween:
			hover_tween.kill()
		if glow_tween:
			glow_tween.kill()
