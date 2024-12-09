> [!note]
> Experimental plugin, feel free to contribute or report any issues to improve compatibility with more web browsers and screen readers.
# Godot-ARIA
A plugin for creating accessible rich internet applications with godot.

Screen Reader | Browsers | Compatibility
| --- | --- | --- |
| NVDA | Firefox, Chrome, Edge | Yes
| JAWS | Firefox, Chrome, Edge | Uknown [#5](https://github.com/btzr-io/godot-aria/issues/5)
| TalkBack | Firefox, Chrome | Uknown https://github.com/btzr-io/godot-aria/issues/9

## Installation
Just add the addons folder to your project and enable the plugin.

See: [Installing a plugin](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html#installing-a-plugin)

## Custom html page
> [!warning]
> The default godot web export HTML page has accessibility [issues](https://github.com/btzr-io/godot-aria/issues/4) and is not compatible with this pluign.

This repository provides a more accessible version that can serve as a starting point: [godot_aria_shell.html](https://github.com/btzr-io/godot-aria/blob/main/addons/godot-aria/godot_aria_shell.html)

```shell
Export > html/custom_html_shell = "res://addons/godot-aria/godot_aria_shell.html"
```

See: [Custom HTML page for Web export](https://docs.godotengine.org/en/stable/tutorials/platform/web/customizing_html5_shell.html#custom-html-page-for-web-export)

## Usage
Global class `GodotARIA`:
```py
  GodotARIA.notify_screen_reader(message: Variant)
```
