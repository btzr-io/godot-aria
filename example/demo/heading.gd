extends RichTextLabel

var aria_role : String = "heading"
var aria_level : int = 1

func _ready() -> void:
	select_all()
