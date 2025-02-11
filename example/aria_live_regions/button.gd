extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _pressed() -> void:
	print(name)
	if name.ends_with('1'):
		GodotARIA.aria_proxy.update_live_region('Success: Test 1', 'polite')
	if name.ends_with('2'):
		GodotARIA.aria_proxy.update_live_region('Success: Test 2', 'polite', true)
	if name.ends_with('3'):
		GodotARIA.aria_proxy.update_live_region('Success: Test 3', 'assertive')
	if name.ends_with('4'):
		GodotARIA.aria_proxy.update_live_region('Success: Test 4', 'assertive', true)
