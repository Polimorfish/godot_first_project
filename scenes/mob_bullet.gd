extends RigidBody2D

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass
