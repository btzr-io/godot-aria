@tool
extends EditorPlugin

# Replace this value with a PascalCase autoload name, as per the GDScript style guide.
const AUTOLOAD_NAME = "GodotARIA"
var export_plugin : WebExportPlugin

func _enter_tree():
	export_plugin = WebExportPlugin.new()
	add_export_plugin(export_plugin)

func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	export_plugin = null

func _enable_plugin():
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/godot-aria/godot_aria.gd")

func _disable_plugin():
	remove_autoload_singleton(AUTOLOAD_NAME)

class WebExportPlugin extends EditorExportPlugin:
	var _plugin_name = "<plugin_name>"
	var file_name = "index.js"
	var export_path : String
	var export_debug : bool

	# Specifies which platform is supported by the plugin.
	func _supports_platform(platform):
		if platform is EditorExportPlatformWeb:
			return true
		return false

	func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int):
		export_path = path.get_base_dir()
		export_debug = is_debug

	func _export_end() -> void:
		# Run from editor:
		if export_debug: file_name = "tmp_js_export.js"
		var engine_js = export_path + "/" + file_name
		# Exported with debug:
		if !FileAccess.file_exists(engine_js):
			engine_js = export_path + "/" + "index.js"
		# Remove permanent focus trap on web export
		if FileAccess.file_exists(engine_js):
			var file = FileAccess.open(engine_js, FileAccess.READ_WRITE)
			var data = file.get_as_text()
			var update = data.replace("func(pressed,evt.repeat,modifiers);evt.preventDefault()", "func(pressed,evt.repeat,modifiers);if(window.GODOT_ARIA_PROXY.is_focus_trap(evt)){evt.preventDefault();}")
			file.resize(0)
			file.store_string(update)
			file.close()

	# Return the plugin's name.
	func _get_name():
		return _plugin_name
