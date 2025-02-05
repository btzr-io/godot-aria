extends Button


func _pressed() -> void:
	get_parent().get_node("ProgressBar").value = 100
