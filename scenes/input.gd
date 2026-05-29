extends Node

@export
var motion = Vector2():
	set(value):
		motion = clamp(value, Vector2(-1, -1), Vector2(1, 1))

@export var speed = 400
@export var can_shot = true
var shooting = false

var bullet_spawn_position_right = Vector2(19, -4)
var bullet_spawn_position_left = Vector2(-19, -4)
var bullet_spawn_position_up = Vector2(0, -23)
var bullet_spawn_position_down = Vector2(0, 23)
var bullet_scene : PackedScene
var current_direction : Vector2

func spawn_bullet():
	var bullet = bullet_scene.instantiate()
	bullet.position = $BulletSpawn.position
	bullet.linear_velocity = current_direction * speed
	add_child(bullet)

# Called when the node enters the scene tree for the first time.
func update() -> void:
	shooting = false
	var m = Vector2()
	if Input.is_action_pressed("move_right"):
		m.x += 1
		owner.get_node("BulletSpawn").position = bullet_spawn_position_right
	if Input.is_action_pressed("move_left"):
		m.x -= 1
		owner.get_node("BulletSpawn").position = bullet_spawn_position_left
	if Input.is_action_pressed("move_up"):
		m.y -= 1
		owner.get_node("BulletSpawn").position = bullet_spawn_position_up
	if Input.is_action_pressed("move_down"):
		m.y += 1
		owner.get_node("BulletSpawn").position = bullet_spawn_position_down
	if Input.is_action_just_pressed("shot"):
		if can_shot:
			spawn_bullet()
			can_shot = false
			shooting = true
			$ShotTimer.start()
	
	motion = m
	
