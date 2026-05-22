extends Node

signal screen_size_updated(size)

@export var mob_scene : PackedScene
@onready var Player = $Players/Player
@onready var mob_spawn_path : Path2D = $MobPath2
var score
var screen_size : Vector2i

func _ready() -> void:
	#ProjectSettings.settings_changed.connect(settings_has_changed)
	pass

func _game_over() -> void:
	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.show_game_over()

func update_screen_size():
	screen_size = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)
	screen_size_updated.emit(screen_size)

func start_game():
	update_screen_size()
	update_spawn_border()
	
	get_tree().call_group("mobs", "queue_free")
	get_tree().call_group("bullets", "queue_free")
	score = 0
	Player.start($StartPosition.position)
	$StartTimer.start()
	$HUD.show_message("Get Ready!")
	$HUD.update_score(score)
	
	Player.set_health()
	
	var max_health = Player.max_health
	for i in range(max_health):
		$HUD.add_health()
	
func _on_mob_timer_timeout() -> void:
	var mob = mob_scene.instantiate()
	
	var mob_spawn_location = $MobPath2/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	mob.position = mob_spawn_location.position
	var direction = mob_spawn_location.rotation + PI / 2
	direction += randf_range(-PI/4,PI/4)
	mob.rotation = direction
	var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)
	add_child(mob)

func _on_score_timer_timeout() -> void:
	score += 1
	$HUD.update_score(score)

func _on_start_timer_timeout() -> void:
	$ScoreTimer.start()
	$MobTimer.start()

func update_spawn_border():
	var curr_curve : Curve2D = mob_spawn_path.curve
	for point_idx in range(curr_curve.point_count-1):
		var pos = curr_curve.get_point_position(point_idx)
		if pos.x:
			pos.x = screen_size.x
		if pos.y:
			pos.y = screen_size.y
		curr_curve.set_point_position(point_idx, pos)
	$MobPath2.curve = curr_curve

func _on_hud_exit() -> void:
	self.get_window().close_requested.emit()

func _on_hud_screen_size_updated(size: Variant) -> void:
	screen_size_updated.emit(size)
	get_viewport().content_scale_size = size
	screen_size = size
