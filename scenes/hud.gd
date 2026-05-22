extends CanvasLayer
signal screen_size_updated(screen_size)
signal start_game
signal exit
@onready var health_container = $HealthContainer

var health_texture
var lieders_list : Dictionary
var lieders_file_path : String = "user://lieders.json"

func _ready() -> void:
	set_lieder_names()
	set_textures()
	
	$Message.text = "Dodge the Creeps!"
	$main_menu.show()

func set_textures() -> void:
	health_texture = ImageTexture.create_from_image(
		Image.load_from_file("res://art/heart.png")
	)

func show_message(text) -> void:
	$Message.text = text
	$Message.show()
	$MessageTimer.start()

func show_game_over() -> void:
	$Score.hide()
	show_message("Game Over!")
	await $MessageTimer.timeout
	
	$NameEnterer.show()
	await $NameEnterer.close
	
	fill_lieders()
	$LiedersTabel.show()
	await $LiedersTabel.close
	
	$Message.text = "Dodge the Creeps!"
	$Message.show()
	
	await get_tree().create_timer(1.0).timeout
	$main_menu.show()
	#$StartButton.show()
	
func update_score(score) -> void:
	$Score.text = str(score)

func show_lieders():
	for lieder in lieders_list.keys():
		pass
		
func get_score() -> int:
	return int($Score.text)

func add_health() -> void:
	var health_ = TextureRect.new()
	health_.texture = health_texture
	health_container.add_child(health_)

func remove_health() -> void:
	var health_item = health_container.get_children()
	if health_item:
		health_item[-1].queue_free()

func write_leaders():
	if lieders_list.size():
		var leaders_file = FileAccess.open(lieders_file_path, FileAccess.WRITE)
		var json_string = JSON.stringify(lieders_list)
		leaders_file.store_line(json_string)

func set_lieder_names():
	if FileAccess.file_exists(lieders_file_path):
		var leaders_file = FileAccess.open(lieders_file_path, FileAccess.READ)
		var json_str : String
		var json : JSON = JSON.new()
		var parse_result : Error
		
		while leaders_file.get_position() < leaders_file.get_length():
			json_str = leaders_file.get_line()
			
			if json_str:
				parse_result = json.parse(json_str)
			
				if parse_result != OK:
					print("JSON parse error ", json.get_error_message(), " in ", json_str, " at line ", json.get_error_line())
					continue
			
				lieders_list = json.data

func _on_start_button_pressed() -> void:
	$StartButton.hide()
	start_game.emit()

func _on_message_timer_timeout() -> void:
	$Message.hide()

func fill_lieders():
	$LiedersTabel.call("fill_table", lieders_list)

func _on_name_enterer_s_confirm(name: Variant) -> void:
	var new_score : int = get_score()
	
	if lieders_list.has(name):
		if lieders_list[name] < new_score:
			lieders_list[name] = new_score
	else:
		lieders_list[name] = new_score
	
	write_leaders()

func _on_name_enterer_s_cancel() -> void:
	$NameEnterer.hide()

func _on_main_menu_single_play() -> void:
	$main_menu.hide()
	start_game.emit()

func _on_main_menu_exit() -> void:
	exit.emit()

func _on_main_menu_settings() -> void:
	$main_menu.hide()
	$Settings.show()
	$Message.text = "SETTINGS"
	await $Settings.close
	$Message.text = "Dodge the Creeps!"
	$main_menu.show()


func _on_settings_screen_size_updated(screen_size : Vector2i) -> void:
	screen_size_updated.emit(screen_size)


func _on_main_menu_network_play() -> void:
	$lobby.show()
	$main_menu.hide()
