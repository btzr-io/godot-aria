extends Button


func _pressed() -> void:
	get_parent().get_node("ProgressBar").value = 100
	# Force application mode
	GodotARIA.focus_canvas()
	get_parent().get_parent().hide()
