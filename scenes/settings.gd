extends CanvasLayer
signal close
signal screen_size_updated

#@onready var menu_button = $UI/Panel/Settings/SettingsBase/Game/HBoxContainer3/VBoxContainer/current_texture/normal_animation
@onready var player_animation_node : AnimatedSprite2D = $UI/Panel/Settings/SettingsBase/Game/HBoxContainer3/VBoxContainer/current_texture/normal_animation
@onready var arc : AspectRatioContainer = $UI/Panel/Container
@onready var panel : Panel = $UI/Panel
@onready var ScaleSL = $UI/Panel/Container/Panel/CenterContainer/Settings/SettingsBase/Game/ScaleFactor/HSlider
@onready var ScaleSL_Value = $UI/Panel/Container/Panel/CenterContainer/Settings/SettingsBase/Game/ScaleFactor/Value
@onready var gui_margin_sl = $UI/Panel/Container/Panel/CenterContainer/Settings/SettingsBase/Game/GUI_margin/gui_scale
@onready var gui_margin_sl_val = $UI/Panel/Container/Panel/CenterContainer/Settings/SettingsBase/Game/GUI_margin/Value

@onready var resolution_ob = $UI/Panel/Container/Panel/CenterContainer/Settings/SettingsBase/Game/Resolution/Resolution
@onready var aspect_ob = $UI/Panel/Container/Panel/CenterContainer/Settings/SettingsBase/Game/Ratio/aspect
@onready var stretch_aspect_ob = $UI/Panel/Container/Panel/CenterContainer/Settings/SettingsBase/Game/StretchAspect/StretchAspect
@onready var scale_mode_ob = $UI/Panel/Container/Panel/CenterContainer/Settings/SettingsBase/Game/StretchMode/StretchScaleMode
@onready var scale_slider_ob = $UI/Panel/Container/Panel/CenterContainer/Settings/SettingsBase/Game/ScaleFactor/HSlider

var player_animations : PackedStringArray
var current_animation_idx : int
var texture_set : Array
var config_hash : int
var global_settings : Dictionary
var pop_menu : Dictionary[int, Array]
var screen_size : Vector2i
var gui_aspect_ratio : float = -1.0
var config = ConfigFile.new()
var config_data : Dictionary = {}
var config_name : String = "user://settings.cfg"
var file_path_prefix = "user://"
var global_settings_file : String = "user://global_settings.json"

var stretch_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
var stretch_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
var scale_factor = 1.0
var gui_margin = 0.0

func find_parameter_in_config(key : String):
	if config_data.has(key):
		return config_data[key]
	print("key : "+key+" in config not found!")
	return null

func get_texture(file) -> ImageTexture:
	return ImageTexture.create_from_image(
		Image.load_from_file(file)
	)

func load_player_textures(texture_set_path):
	var path = "res://".path_join(texture_set_path)
	var files = DirAccess.open(path).get_files()
	for file in files:
		texture_set.append(get_texture(file))

func set_settings_from_cfg():
	var config_sections = config.get_sections()
	if config_sections.size():
		for section in config_sections:
			for key_section in config.get_section_keys(section):
				config_data[key_section] = {"section":section, "value":config.get_value(section, key_section)}
		if config_data.has("texture_source"):
			load_player_textures(config_data.get("texture_source")["value"])
		if config_data.has("current_texture"):
			current_animation_idx = config_data.get("current_texture")["value"]
	else:
		return ERR_PARAMETER_RANGE_ERROR
	return OK

func load_cfg(cfg_file : String):
	if FileAccess.file_exists(cfg_file):
		var err = config.load(cfg_file)
		if err == OK:
			err = set_settings_from_cfg()
			if err == OK:
				config_hash = hash(config_data)
				return OK
			return null
		return null
	return null

func read_from_json(json_file):
	if FileAccess.file_exists(json_file):
		var descriptor = FileAccess.open(json_file, FileAccess.READ)
		var json_str : String
		var json : JSON = JSON.new()
		var parse_result : Error
		
		while descriptor.get_position() < descriptor.get_length():
			json_str = descriptor.get_line()
			
			if json_str:
				parse_result = json.parse(json_str)
			
				if parse_result != OK:
					print("JSON parse error ", json.get_error_message(), " in ", json_str, " at line ", json.get_error_line())
					return ERR_PARSE_ERROR
				
				global_settings = json.data
		descriptor.close()
	else:
		return ERR_FILE_NOT_FOUND
	return OK

func set_global_settings():
	if read_from_json(global_settings_file) == OK:
		return OK

func update_config_value(key : String, value: Variant):
	if find_parameter_in_config(key):
		var section = config_data.get(key)["section"]
		config.set_value(section, key, value)

func get_walk_animations(animations) -> PackedStringArray:
	var walk_animations : PackedStringArray
	for anim : String in animations:
		if anim.contains("walk"):
			walk_animations.append(anim)
	return walk_animations

func get_current_animation():
	pass

func get_prev_animation():
	if (current_animation_idx - 1) >= 0:
		return current_animation_idx - 1
	return player_animations.size() - 1

func get_next_animation():
	if (current_animation_idx + 1) != player_animations.size():
		return current_animation_idx + 1
	return 0

func change_animation():
	update_config_value("current_texture", current_animation_idx)
	#player_animation_node.play(player_animations.get(current_animation_idx))

func get_current_settings():
	screen_size = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")	
	)

func update_settings_from_project():
	if ProjectSettings.has_setting("display/window/stretch/aspect"):
		var parameter = ProjectSettings.get_setting("display/window/stretch/aspect")
		match parameter:
			"expand":
				stretch_aspect_ob.select(4)

func _ready() -> void:
	update_settings_from_project()
	if load_cfg(config_name) == OK:
			
		var nodes_in_group = get_tree().get_nodes_in_group("menu_buttons")
		var id : int = 0
		
		for node in nodes_in_group:
			var popup : PopupMenu = node.get_popup()
			
			if config_data.has(node.name):
				node.text = config_data[node.name]["value"]
			else:
				node.text = "!"
			
			if global_settings.has(node.name):
				for item in global_settings[node.name]:
					popup.add_item(item, id)
					pop_menu[id] = [popup, node]
					id += 1
			
			popup.id_pressed.connect(popup_press)
	
	#if set_global_settings() == OK:
	if is_instance_of(player_animation_node, AnimatedSprite2D):
		player_animations = get_walk_animations(player_animation_node.sprite_frames.get_animation_names())
		if current_animation_idx != null:
			player_animation_node.play(player_animations[current_animation_idx])
		else:
			player_animation_node.play("walk")
	
	if owner:
		hide()

func update_container():
	for i in 2:
		if is_equal_approx(gui_aspect_ratio, -1.0):
			arc.ratio = panel.size.aspect()
		else:
			arc.ratio = min(panel.size.aspect(), gui_aspect_ratio)
		

func menu_button_press():
	pass

func popup_press(id : int):
	var popup : PopupMenu = pop_menu[id][0]
	var menu : MenuButton = pop_menu[id][1]
	menu.text = popup.get_item_text(popup.get_item_index(id))
	
	for section in config.get_sections():
		if config.has_section_key(section, menu.name):
			config.set_value(section, menu.name, menu.text)
			break

func _on_save_pressed() -> void:
	config.save(config_name)
	#var size_dict : Dictionary = find_parameter_in_config("resolution")
	if screen_size != null:
		#current_window.child_controls_changed()
		ProjectSettings.set_setting("display/window/size/viewport_height", screen_size.y)
		ProjectSettings.set_setting("display/window/size/viewport_width", screen_size.x)
		#ProjectSettings.save_custom("override.cfg")
		ProjectSettings.save()
		ProjectSettings.settings_changed.emit()

func _on_exit_pressed() -> void:
	if owner:
		hide()
		close.emit()
	else:
		self.get_window().close_requested.emit()

func _on_texture_left_slide_pressed() -> void:
	current_animation_idx = get_next_animation()
	change_animation()

func _on_texture_right_slide_pressed() -> void:
	current_animation_idx = get_prev_animation()
	change_animation()


func _on_resolution_item_selected(index: int) -> void:
		match index:
			0:  # 648×648 (1:1)
				screen_size = Vector2(648, 648)
			1:  # 640×480 (4:3)
				screen_size = Vector2(640, 480)
			2:  # 720×480 (3:2)
				screen_size = Vector2(720, 480)
			3:  # 800×600 (4:3)
				screen_size = Vector2(800, 600)
			4:  # 1152×648 (16:9)
				screen_size = Vector2(1152, 648)
			5:  # 1280×720 (16:9)
				screen_size = Vector2(1280, 720)
			6:  # 1280×800 (16:10)
				screen_size = Vector2(1280, 800)
			7:  # 1680×720 (21:9)
				screen_size = Vector2(1680, 720)
		if owner:
			var root_node = owner.get_tree().root
			#root_node.content_scale_size = screen_size
		else:
			#get_viewport().content_scale_size = screen_size
			update_container.call_deferred()
		screen_size_updated.emit(screen_size)


func _on_aspect_item_selected(index: int) -> void:
	match index:
		0:  # Fit to Window
			gui_aspect_ratio = -1.0
		1:  # 5:4
			gui_aspect_ratio = 5.0 / 4.0
		2:  # 4:3
			gui_aspect_ratio = 4.0 / 3.0
		3:  # 3:2
			gui_aspect_ratio = 3.0 / 2.0
		4:  # 16:10
			gui_aspect_ratio = 16.0 / 10.0
		5:  # 16:9
			gui_aspect_ratio = 16.0 / 9.0
		6:  # 21:9
			gui_aspect_ratio = 21.0 / 9.0
	
	update_container.call_deferred()


func _on_stretch_mode_item_selected(index: int) -> void:
	stretch_aspect = index
	get_viewport().content_scale_aspect = stretch_aspect


func _on_h_slider_drag_ended(value_changed: bool) -> void:
	scale_factor = ScaleSL.value
	ScaleSL_Value.text = "%d%%" % (scale_factor * 100)
	
func _on_stretch_scale_mode_item_selected(index: int) -> void:
	get_viewport().content_scale_stretch = index


func _on_gui_scale_drag_ended(value_changed: bool) -> void:
	gui_margin = gui_margin_sl.value
	gui_margin_sl_val.text = str(gui_margin)
	update_container.call_deferred()
