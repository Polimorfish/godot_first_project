extends CanvasLayer

signal s_confirm(name)
signal s_cancel
signal close

@onready var name_field = $NameInput

func _ready() -> void:
	hide()

func _on_confirm_pressed() -> void:
	var input_name = name_field.text
	if ! input_name:
		$AnimationTree.play("wrong_input")
		return
	hide()
	s_confirm.emit(input_name)
	close.emit()
	
func _on_cancel_pressed() -> void:
	s_cancel.emit()
	hide()
	close.emit()
