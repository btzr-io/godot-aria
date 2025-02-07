extends CenterContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Open_Shop"):
		print("S")
		var content : Control = get_node("Content")
		if !content.is_visible_in_tree():
			content.show()
