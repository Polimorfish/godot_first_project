extends CanvasLayer

signal close

var columns : Array

func _ready() -> void:
	columns = ["Игрок", "Счет"]
	$list.max_columns = columns.size()
	hide()

func add_headers():
	for column in columns:
		$list.add_item(column, null, false)

func fill_table(items):
	$list.clear()
	add_headers()
	
	if typeof(items) == TYPE_DICTIONARY:
		for item in items.keys():
			$list.add_item(item, null, false)
			$list.add_item(str(items[item]), null, false)

func _on_close_pressed() -> void:
	hide()
	close.emit()
