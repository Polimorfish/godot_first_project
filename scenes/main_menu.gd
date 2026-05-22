extends CanvasLayer

signal single_play
signal network_play
signal settings
signal exit

func _on_start_single_pressed() -> void:
	single_play.emit()

func _on_start_coop_pressed() -> void:
	network_play.emit()

func _on_setting_pressed() -> void:
	settings.emit()

func _on_exit_pressed() -> void:
	exit.emit()
