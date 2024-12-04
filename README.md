# Godot-ARIA
A plugin for creating accessible rich internet applications with godot.

## Installation
Just add the addons folder to your project and enable the plugin.

See [Installing a plugin](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html#installing-a-plugin)

## Custom html page

While the web export templates provide a default HTML page it needs a few tweaks to make it compatible with this plugin, so you should use the [godot_aria_shell.html](https://github.com/btzr-io/godot-aria/blob/main/addons/godot-aria/godot_aria_shell.html) as the default or a starting point:

```shell
Export > html/custom_html_shell = "res://addons/godot-aria/godot_aria_shell.html"
```

See: [Custom HTML page for Web export](https://docs.godotengine.org/en/stable/tutorials/platform/web/customizing_html5_shell.html#custom-html-page-for-web-export)

## Usage
Global class `GodotARIA`:
```py
  GodotARIA.notify_screen_reader(message: Variant)
```
