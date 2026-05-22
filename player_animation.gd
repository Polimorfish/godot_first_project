extends Node2D

var __animations : Array

func get_animations():
	return __animations

func get_root_parent(parent):
	if parent.get_parent():
		get_root_parent(parent.get_parent())
	return parent

func _ready() -> void:
	__animations = get_children()
