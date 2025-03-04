@tool
@icon('res://addons/godot-aria/nodes/web_text_input/icon.svg')
extends PanelContainer
class_name WebTextInput

## Hybrid control that renders a native <input> element on top of the godot canvas.
##
## The global transform and modulate alpha is synced to css transform and opacity.
## @experimental

var content_scene = preload("res://addons/godot-aria/nodes/web_text_input/content.tscn")

signal on_input(event: JavaScriptObject)
signal on_change(event: JavaScriptObject)
signal on_keydown(event: JavaScriptObject)

const INPUT_TYPES = "text,email,date,date-local,month,number,password,tel,time,search,url,week"
const INPUT_MODES = "none,text,email,decimal,numeric,tel,search,url"
const TEXT_ALIGN = "left,right,center,justify"
const TEXT_TRANSFORM = "none,capitalize,uppercase,lowercase,full-width,full-size-kana,math-auto"
## The id global attribute defines an identifier (ID) for the <input> element which must be unique in the whole document.
@export var id  : String
## A string specifying the type of <input> element to render.
@export_custom(PROPERTY_HINT_ENUM, INPUT_TYPES) var type: String = "text"
## Provides a hint to browsers as to the type of virtual keyboard configuration to use when editing this element or its contents.
@export_custom(PROPERTY_HINT_ENUM, INPUT_MODES) var input_mode : String
## A string containing the value of the <input> element, or the empty string if the input element has no value set.
@export var value : String = "" :
	set(next_value):
		if ref:
			ref.element.value = next_value
	get():
		if ref:
			return ref.element.value
		return value
		
## Text that appears when the <input> element has no value set
@export var placeholder : String = "Placeholder text"
## Attribute to provide an accessible name for the <input> element
@export var aria_label : String
## Hint for form autofill feature
@export var auto_complete : String = "off"
## Maximum length (number of characters) of value
@export_range(0, 254, 1,"or_great") var max_length : int = 0
## Attribute that defines whether the <input> element may be checked for spelling errors.
@export var spell_check : bool = false
## Boolean attribute, when present, the user can neither edit nor focus on <input> element.
@export var disabled: bool = false :
	set(value):
		disabled = value
		set_style(disabled_style if value else normal_style)
		if (GODOT_ARIA_UTILS.is_web()) and ref:
			ref.element.disabled = value

@export_category("Styles")
@export var disabled_style : StyleBox : 
	set(value):
		disabled_style = value
		if disabled:
			set_style(value)
@export var focus_style : StyleBox
@export var normal_style : StyleBox :
	set(value):
		normal_style = value
		set_style(value)
@export_subgroup("Text")
@export_range(1, 9999, 1, 'suffix:px') var text_size : int = 16 :
	set(value):
		text_size = value
		update_label_height(value)
		set_css_property('--text_size', str(value) + 'px')
@export_custom(PROPERTY_HINT_ENUM, TEXT_ALIGN) var text_align : String = "left" :
	set(value):
		text_align = value
		set_css_property('--text_align', value)
@export_custom(PROPERTY_HINT_ENUM, TEXT_TRANSFORM) var text_transform : String = "none" :
	set(value):
		text_transform = value
		set_css_property('--text_transform', value)
@export var text_font : String :
	set(value):
		text_font = value
		set_css_property('--text_font', value)
@export_subgroup("Colors")
@export var text_color : Color :
	set(value):
		placeholder_color = value
		set_css_property('--text_color', value)
		
@export var placeholder_color : Color :
	set(value):
		placeholder_color = value
		set_css_property('--placeholder_color', value)
		
@export var selection_color : Color :
	set(value):
		selection_color = value
		set_css_property('--selection_color', value)
		
@export var selection_text_color : Color :
	set(value):
		selection_text_color = value
		set_css_property('--selection_text_color', value)

var box : PanelContainer
var overlay_target : Label
var ref : HtmlReference
var parent_control : Variant
var parent_module : Variant
var parent_element : JavaScriptObject

# Events callbacks
var html_input_cb = JavaScriptBridge.create_callback(handle_html_input)
var html_change_cb = JavaScriptBridge.create_callback(handle_html_change)
var html_focus_cb = JavaScriptBridge.create_callback(handle_html_focus)
var html_focusout_cb = JavaScriptBridge.create_callback(handle_html_focusout)
var html_keydown_cb = JavaScriptBridge.create_callback(handle_html_keydown)
# Cache transforms
var element_transform : Dictionary
var prev_element_transform : Dictionary = {}
var godot_aria : Variant

@export_storage var cache_init_min_size = null
@export_storage var cache_init_focus_mode = null
@export_storage var cache_init_clip_contents = null

func set_style(new_style):
	if box and new_style:
		box.add_theme_stylebox_override('panel', new_style)

func has_html_focus() -> bool :
	if GODOT_ARIA_UTILS.is_web() and godot_aria and ref and ref.element:
		return godot_aria.aria_proxy.has_focus(ref.element)
	return false
	
func set_css_property(property_name, property_value):
	if GODOT_ARIA_UTILS.is_web() and ref and ref.element:
		var formated = property_value
		if formated is Color:
			formated = GODOT_ARIA_UTILS.to_css_color(formated)
		ref.element.style.setProperty(property_name, formated)

func _init():
	if GODOT_ARIA_UTILS.is_web():
		godot_aria = GODOT_ARIA_UTILS.get_safe_autoload()
		
func _enter_tree() -> void:
	# Don't render for non web builds
	if !Engine.is_editor_hint() and !OS.has_feature("web"):
			visible = false
	# Default configuration
	if Engine.is_editor_hint():
		if cache_init_clip_contents == null:
			clip_contents = true
			cache_init_clip_contents = clip_contents
		if cache_init_min_size == null:
			custom_minimum_size.x = 100
			custom_minimum_size.y = 24
			cache_init_min_size = custom_minimum_size
		if cache_init_focus_mode == null:
			focus_mode = FOCUS_ALL
			cache_init_focus_mode = focus_mode
	# Render contents if is editor or web:
	if (Engine.is_editor_hint() or OS.has_feature("web")) and !get_node_or_null("Box"):
		box = content_scene.instantiate()
		overlay_target = box.get_node_or_null("Label")
		add_child(box)
	# Set initial styles in editor
	if Engine.is_editor_hint():
		set_style(disabled_style if disabled else normal_style)
	update_label_height(text_size)
	var current_style : StyleBox = get_theme_stylebox("panel")
	if current_style  is not StyleBoxEmpty:
		add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	
	if GODOT_ARIA_UTILS.is_web():
		set_notify_transform(true)
		visibility_changed.connect(handle_visibility)
		focus_entered.connect(handle_focus)
		focus_exited.connect(handle_blur)
		# Initial value for element attributes
		var init_props = {
			'type': type,
			'value': value,
			'disabled': disabled,
			'ariaLabel': aria_label,
			'placeholder': placeholder,
			'spellcheck': spell_check,
			# Focus managment is controled by godot and not the browser:
			'tabIndex': -1,
		}
		# Conditional props
		if max_length > 0:
			init_props['maxLength'] = max_length
			
		if auto_complete:
			init_props['autocomplete'] = auto_complete
		# Html element reference
		parent_element = _get_parent_element()
		ref = HtmlReference.new(id, "input", init_props, "overlay", parent_element)
		ref.element.addEventListener("focus", html_focus_cb)
		ref.element.addEventListener("focusout", html_focusout_cb)
		ref.element.addEventListener("input", html_input_cb)
		ref.element.addEventListener("change", html_change_cb)
		ref.element.addEventListener("keydown", html_keydown_cb)
		# Initial visibility
		handle_visibility()

#func _get_parent_element() -> Variant:
	#if !godot_aria: return null
	#parent_control = godot_aria.get_parent_in_accesibility_tree(overlay_target)
	#parent_module = godot_aria.get_accessible_node(parent_control)
	## Prevent invalid hierarchy
	#if parent_module:
		## Only text content should be indside reading mode
		#if parent_module.role == "document":
			#return null
		#return parent_module.ref.element
	#return null

func _get_parent_element() -> Variant:
	if godot_aria:
		parent_control = godot_aria.get_parent_in_accesibility_tree(overlay_target)
		parent_module = godot_aria.get_accessible_node(parent_control)
	# Prevent invalid hierarchy
	if parent_module:
		# Only text content should be indside reading mode
		if parent_module.role == "document":
			return null
		return parent_module.ref.element
	return null
	
func update_label_height(value):
	if overlay_target:
		overlay_target.custom_minimum_size.y = value

func update_color_styles() -> void:
	if !ref or !ref.element: return
	var prop_colors = ['text_color', 'placeholder_color', 'selection_color', 'selection_text_color']
	for prop_name in prop_colors:
		var prop_value : Color = self[prop_name]
		if prop_value: set_css_property("--" + prop_name, prop_value)

func update_text_styles() -> void:
	if text_size:
		set_css_property('--text_size', str(text_size) + 'px')
	if text_font:
		set_css_property('--text_font', str(text_font))
	if text_align:
		set_css_property('--text_align', str(text_align))
	if text_transform:
		set_css_property('--text_transform', str(text_transform))

func handle_visibility():
	var is_visible: bool = is_visible_in_tree()
	ref.update_style({'display': 'block' if is_visible else 'none'})
	
func handle_focus() -> void:
	if disabled: return
	set_style(focus_style)
	if GODOT_ARIA_UTILS.is_web() and godot_aria:
		ref.element.focus()
		godot_aria.aria_proxy.set_active_descendant()

func handle_blur():
	if godot_aria:
		ref.element.blur()
		godot_aria.focus_canvas()

	if disabled: return
	set_style(normal_style)

func handle_html_focus(args):
	grab_focus()
	if godot_aria:
		godot_aria.aria_proxy.canvas.tabIndex = -1
		godot_aria.aria_proxy.toggle_focus_redirect(false)

func handle_html_focusout(args):
	release_focus()
	if godot_aria:
		godot_aria.aria_proxy.canvas.tabIndex = 0
		godot_aria.aria_proxy.toggle_focus_redirect(true)

func handle_html_input(args):
	on_input.emit(args[0])

func handle_html_change(args):
	on_change.emit(args[0])

func handle_html_keydown(args):
	var html_event : JavaScriptObject = args[0]
	var prevent_arrow_keys = false
	
	if godot_aria.aria_proxy.is_focus_trap(html_event, prevent_arrow_keys):
		html_event.preventDefault()
		if html_event.key == "Tab" and html_event.shiftKey:
			godot_aria.focus_manager.restore_focus("PREV")
			
		elif html_event.key == "Tab" and !html_event.shiftKey:
			godot_aria.focus_manager.restore_focus("NEXT")
	
	# Expose signal for html event
	on_keydown.emit(html_event)
	
func _notification(what: int) -> void:
	if GODOT_ARIA_UTILS.is_web():
		if what == NOTIFICATION_PREDELETE and ref:
			ref.free()
		if what == NOTIFICATION_TRANSFORM_CHANGED:
			force_redraw()

func force_redraw():
	element_transform = GODOT_ARIA_UTILS.get_control_css_transform(overlay_target, parent_control)
	if element_transform.hash() != prev_element_transform.hash():
		prev_element_transform = element_transform
		queue_redraw()
		
func _draw() -> void:
	if !GODOT_ARIA_UTILS.is_web() or !element_transform: return
	godot_aria.aria_proxy.redraw_element(
		ref.element,
		GODOT_ARIA_UTILS.dictionary_to_js(element_transform),
		GODOT_ARIA_UTILS.get_modulate_in_tree(overlay_target)
	)
		
func _ready() -> void:
	# Initial render
	if GODOT_ARIA_UTILS.is_web():
		set_style(disabled_style if disabled else normal_style)
		update_color_styles()
		update_text_styles()
		await(get_tree().process_frame)
		force_redraw()
