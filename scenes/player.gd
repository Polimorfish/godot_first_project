extends Area2D
signal hit
signal die

@export var speed = 400
@export var bullet_scene : PackedScene
@export var synced_position := Vector2()

@onready var Inputs = $Inputs

var max_health = 3
var current_health : int
var acceleration = Vector2(100, 100)

var screen_size : Vector2i
var velocity = Vector2.ZERO
var bullet_spawn_position_right = Vector2(19, -4)
var bullet_spawn_position_left = Vector2(-19, -4)
var bullet_spawn_position_up = Vector2(0, -23)
var bullet_spawn_position_down = Vector2(0, 23)
var can_shot = true
var bullet_collision_mask = 0x0000 # the mask is 00000110
var current_direction : Vector2
var player_name = "lol"

func update_screen_size():
	if ! screen_size:
		screen_size = Vector2i(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height")	
		)

func set_player_name(name):
	get_node("Label").text = name

func _ready() -> void:
	
	update_screen_size()
	$BulletSpawn.position = bullet_spawn_position_right
	position = synced_position
	
	if str(name).is_valid_int():
		get_node("Input/InputSync").set_multiplayer_authority(str(name).to_int())
	print(multiplayer.multiplayer_peer)
	hide()

func _process(delta: float) -> void:
	Inputs.update()
	#Здесь вызывается метод для обработки ввода пользователя в любом случае
	#Не понятно в каком случае определяется multipleer_peer и как по нему определить
		#является ли узел клиентом или сервером
	
	if multiplayer.multiplayer_peer == null or str(multiplayer.get_unique_id()) == str(name):
		Inputs.update()
	
	#Если нет объекта для обработки системы rpc или локальная система - многопользовательский центр узла
	if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
		synced_position = position
		if is_multiplayer_authority() and Inputs.shooting:
			pass #Создаем пулю в сцене
	else:
		position = synced_position
	
	velocity = Inputs.motion
	
	if velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0
	elif velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x < 0
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		current_direction = velocity.normalized()
		if not $AnimatedSprite2D.is_playing():
			$AnimatedSprite2D.play()
	else:
		if $AnimatedSprite2D.is_playing():
			$AnimatedSprite2D.stop()
	
	update_position(velocity, delta)
	
func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false

func _set_process_mode_(mode : int):
	process_mode = mode

func get_current_health():
	return current_health

func get_max_health():
	return max_health

func set_health(value = max_health):
	current_health = value

func update_position(velocity, delta):
	if velocity:
		position += velocity * delta
		position = position.clamp(Vector2.ZERO, screen_size)

func spawn_bullet():
	var bullet = bullet_scene.instantiate()
	bullet.position = $BulletSpawn.position
	bullet.linear_velocity = current_direction * speed
	add_child(bullet)
	
func _on_body_entered(body: Node2D) -> void:
	hit.emit()

func _on_shot_timer_timeout() -> void:
	can_shot = true

func _on_start_timer_timeout() -> void:
	_set_process_mode_(Node.PROCESS_MODE_INHERIT)

func _on_hit() -> void:
	current_health -= 1
	$AnimationPlayer.play("hit")
	if !current_health:
		die.emit()

func _on_die() -> void:
	hide()
	$CollisionShape2D.set_deferred("disabled", true)
	_set_process_mode_(Node.PROCESS_MODE_PAUSABLE)

func _on_body_shape_entered(body_rid: RID, body: Node2D,body_shape_index: int,	local_shape_index: int) -> void:
	
	var body_shape_owner = body.shape_find_owner(body_shape_index)
	var body_shape_node = body.shape_owner_get_owner(body_shape_owner)
	
	var local_shape_owner = shape_find_owner(local_shape_index)
	var local_shape_node = shape_owner_get_owner(local_shape_owner)
	
func _on_main_screen_size_updated(new_screen_size : Vector2i) -> void:
	screen_size = new_screen_size
