extends ScrollContainer

var aria_role = "region"
var aria_label = "Output"
var last_item_active

@onready var list = $MessageList

func _ready() -> void:
	focus_entered.connect(handle_focus)
	focus_exited.connect(handle_focus_exit)
	
func focus_trap():
	if has_focus() and list.get_child_count() > 0:
		get_viewport().set_input_as_handled()

func focus_next_item():
	if last_item_active:
		var next_index = last_item_active.get_index() + 1
		if list.get_child_count() > next_index:
			focus_item(next_index)

func focus_prev_item():
	if last_item_active:
		var prev_index = last_item_active.get_index() - 1
		if list.get_child_count() > 0 and prev_index > -1:
			focus_item(prev_index)	
					
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up", true):
		focus_prev_item()
		focus_trap()
	if event.is_action_pressed("ui_down", true):
		focus_next_item()
		focus_trap()
		
func handle_focus():
	focus_last_item()
	
func handle_focus_exit():
	if is_instance_valid(last_item_active):
		last_item_active.active = false
		last_item_active = null
	
func focus_first_item():
	if list.get_child_count() > 0:
		focus_item(0)

func focus_last_item():
	var last_item_index =  list.get_child_count() - 1
	if last_item_index > -1:
		focus_item(last_item_index)

func focus_item(item_index):
	if is_instance_valid(last_item_active):
		last_item_active.active = false
		last_item_active = null
	var item = list.get_child(item_index)
	item.active = true
	ensure_control_visible(item)
	last_item_active = item
	
