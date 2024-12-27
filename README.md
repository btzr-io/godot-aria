> [!note]
> Experimental plugin, feel free to contribute or report any issues to improve compatibility with more web browsers and screen readers.

# Godot-ARIA
A plugin for creating accessible rich internet applications with godot.

For more information about screen readers and browsers compatibility please see: [current live region behaviour](https://tetralogical.com/blog/2024/05/01/why-are-my-live-regions-not-working/#current-live-region-behaviour).


### Features
- Accessible html page template.
- Notifiy changes or important alerts to screen readers.
- Restore or gain focus with tab / shift + tab navigation.
- Focus can leave the canvas element to navigate other content on the web page.
- Accessibility module for Node2D.

## Installation
Just add the addons folder to your project and enable the plugin.

See: [Installing a plugin](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html#installing-a-plugin)

## Export configuration
> [!warning]
> The default godot web export HTML page has accessibility [issues](https://github.com/btzr-io/godot-aria/issues/4) and is not compatible with this pluign.

Before you can use this addon you need to make some quick changes to the export settings:

- This repository provides a more accessible HTML page that can serve as a starting point: [godot_aria_shell.html](https://github.com/btzr-io/godot-aria/blob/main/addons/godot-aria/godot_aria_shell.html)

- Auto focus behavior is not recommended, the user should decide when to enter focus ( click or tab navigation ).
  
```shell
Export > html/custom_html_shell: "res://addons/godot-aria/godot_aria_shell.html"
Export > html/focus_canvas_on_start: false
```

See: [Custom HTML page for Web export](https://docs.godotengine.org/en/stable/tutorials/platform/web/customizing_html5_shell.html#custom-html-page-for-web-export)

## Usage
Global class `GodotARIA` provides methods to manage focus for the html canvas element and a way to send notifications or alerts to screen readers as [aria-live](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-live) updates.
### GodotARIA.focus_canvas
Focus the current canvas element.
```py
  GodotARIA.focus_canvas()
```

### GodotARIA.unfocus_canvas
Remove focus of the current canvas element.
```py
  GodotARIA.unfocus_canvas()
```

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

## Accessibiltiy module for Node2D
To make any Node2D accessible you can add the custom node AccessibleModule as a direct child, this will create an overlay control to handle the focus behavior.

### Features
- Add focus behavior.
- Custom focus style.
- Tab navigation between other focusable elements.
- Notify name or description to screen readers on focus.

### Properties
#### aria_label : String
Name or description to be anounced by screen readers.

#### focus_mode : Control.FocusMode
Focus mode of the overlay control: None, Click, All.

#### focus_size : Vector2
The focusable area size, calculated by default if the node has a visible texture or rect.

#### focus_style : StyleBox
Add a custom style if needed, otherwise you can use has_focus() and apply a custom focus indicator on the node.

#### focus_control
Reference of the overlay control that manages the focus behavior, use this property to interact directly with the overlay control.

### Methods

#### grab_focus
Focus the overlay control.

#### has_focus
Checks if the overlay control has focus.
