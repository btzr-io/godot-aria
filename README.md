> [!note]
> Experimental plugin, feel free to contribute or report any issues to improve compatibility with more web browsers and screen readers.
# Godot-ARIA
A plugin for creating accessible rich internet applications with godot.

Screen Reader | Browsers | Compatibility
| --- | --- | --- |
| NVDA | Firefox, Chrome, Edge | Yes


For information about other screen readers or browsers, please see: [current live region behaviour](https://tetralogical.com/blog/2024/05/01/why-are-my-live-regions-not-working/#current-live-region-behaviour).

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
Global class `GodotARIA` provides a way to send messages and alerts to screen readers as [aria-live](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-live) updates.

### GodotARIA.notify_screen_reader
Awaits for a natural pause before speaking up. It won’t interrupt what the screen reader is currently announcing. Equivalent to aria-live [polite](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-live#polite).
```py
  GodotARIA.notify_screen_reader(message: String)
```

### GodotARIA.alert_screen_reader
Speak an alert, interrupts whatever the screen reader is currently announcing. Equivalent to aria-live [assertive](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-live#assertive).
```py
  GodotARIA.alert_screen_reader(message: String)
```
