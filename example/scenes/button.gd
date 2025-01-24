extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(test)
	pass # Replace with function body.


func test():
	print("Trigger from signal!")
	
func _pressed() -> void:
	print("Trigger!")
