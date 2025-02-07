@tool
extends Tree


func _ready():
	var root = create_item()
	var subchild1 = create_item(root)
	root.set_text(0, "root")
	subchild1.set_text(0, "Subchild1")
