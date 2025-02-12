extends Button

func _pressed() -> void:
	if name.ends_with('1'):
		GodotARIA.aria_proxy.update_live_region('Success: Test 1', 'polite')
	if name.ends_with('2'):
		GodotARIA.aria_proxy.update_live_region('Success: Test 2', 'polite', true)
	if name.ends_with('3'):
		GodotARIA.aria_proxy.update_live_region('Success: Test 3', 'assertive')
	if name.ends_with('4'):
		GodotARIA.aria_proxy.update_live_region('Success: Test 4', 'assertive', true)
