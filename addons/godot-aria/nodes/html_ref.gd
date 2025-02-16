extends Object
class_name HtmlReference
var id : String
var element : JavaScriptObject
var godot_aria : Variant

# Constructor
func _init(element_id : String, tag : String = "div",  props : Dictionary = {}, layer = "overlay", parent_element = null):
	var initProps : JavaScriptObject = GODOT_ARIA_UTILS.dictionary_to_js(props)
	id = element_id
	godot_aria = GODOT_ARIA_UTILS.get_safe_autoload()
	if godot_aria:
		element = godot_aria.aria_proxy.create_element_reference(tag, id, initProps, layer, parent_element)
		
# Destructor
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if godot_aria:
			godot_aria.aria_proxy.remove_element_reference(id)
			
# Metods
func update_props(props : Dictionary = {}): 
	GODOT_ARIA_UTILS.dictionary_to_js(props, element)
	
func update_style(styles : Dictionary = {}): 
	GODOT_ARIA_UTILS.dictionary_to_js(styles, element.style)
