extends RigidBody2D

signal hit

var PhysicBody : PhysicsDirectBodyState2D

@export var bullet_scene : PackedScene

var collider_data : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var sprite_set = Array($AnimatedSprite2D.sprite_frames.get_animation_names())
	$AnimatedSprite2D.animation = sprite_set.pick_random()
	$AnimatedSprite2D.play()
	
	if randi_range(0, 1) == 1:
		$BulletSpawn.start()

func get_bullet_position():
	return $BulletPosition.position

func spawn_bullet():
	var bullet = bullet_scene.instantiate()
	bullet.position = $BulletPosition.position
	bullet.linear_velocity = linear_velocity * 2
	
	add_child(bullet)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_bullet_spawn_timeout() -> void:
	spawn_bullet()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var contact_collider : RID
	var contact_collider_id : int
	var contact_collider_object : Object
	var contact_collider_position : Vector2
	var contact_collider_shape : int
	var contact_collider_velocity_at_position : Vector2
	var contact_impilse : Vector2
	
	for idx in state.get_contact_count():
		contact_collider = state.get_contact_collider(idx)
		contact_collider_id = state.get_contact_collider_id(idx)
		contact_collider_object = state.get_contact_collider_object(idx)
		contact_collider_position = state.get_contact_collider_position(idx)
		contact_collider_shape = state.get_contact_collider_shape(idx)
		contact_collider_velocity_at_position = state.get_contact_collider_velocity_at_position(idx)
		contact_impilse = state.get_contact_impulse(idx)

func _on_body_entered(body: Node) -> void:
	hit.emit()
	queue_free()
	body.queue_free()
