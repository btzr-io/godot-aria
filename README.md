> [!note]
> Experimental plugin, feel free to contribute or report any issues to improve compatibility with more web browsers and screen readers.

# Godot-ARIA
A plugin for creating accessible rich internet applications with godot.

### Features
- Accessible html page template.
- Notifiy changes or important alerts to screen readers.
- Expose Control nodes to the browser accesibility tree.
- Screen reader visual focus highlighter.
- Media features detection (reduce motion, contrast preferences, light / dark theme)
- Restore or gain focus with tab / shift + tab navigation.
- Focus can leave the canvas element to navigate other content on the web page.
- Native html text input element as an hybrid control node ( replacement for LineEdit control )

### Current screen reader support:
- NVDA for Windows works very well across all major browsers ( Chrome based and Firefox ).  
- JAWS for Window works better with Google chrome or similar browsers (Brave, Edge, Opera).
- ORCA for Linux works well with Firefox, Google chrome will not announce live region updates.

### Planned support:
- Voice over for MacOs
  
## Installation
Just add the addons folder to your project and enable the plugin or install from the godot [assets library](https://godotengine.org/asset-library/asset/3584).

See: [Installing a plugin](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html#installing-a-plugin)

## Export configuration
> [!warning]
> The default godot web export HTML page has accessibility [issues](https://github.com/btzr-io/godot-aria/issues/4) and is not compatible with this pluign.

This repository provides a more accessible HTML page that can serve as a starting point: [godot_aria_shell.html](https://github.com/btzr-io/godot-aria/blob/main/addons/godot-aria/godot_aria_shell.html)

Before you can use this addon you need to make some quick changes to the export settings:

```shell
Export > html/custom_html_shell: "res://addons/godot-aria/godot_aria_shell.html"
```

See: [Custom HTML page for Web export](https://docs.godotengine.org/en/stable/tutorials/platform/web/customizing_html5_shell.html#custom-html-page-for-web-export)

## Usage

### Accessible Node
A control exposed to the accessiblity tree has an AccessibleNode as a child.

Text content and some interactive controls will be automatically exposed to the accesibility tree as hidden dom elements with aria role and attributes:
- Button -> role='button'
- Checkbox -> role='checkbox'
- Checkbutton -> role='switch'
- Label and RichTextLabel -> role='paragraph'
- Progressbar -> role='progressbar'
- Slider -> role='slider'

To expose other controls to the accesibiliy tree make sure to declare the aria_role variable:
```gdscript
extends Container

# Declaring a valid aria role will expose the control to the accesibility tree
var aria_role = "region"
```

Declaring aria_* prefixed variables indside a control node will set or overwrite the initial value of an aria attribute of the hidden dom element.

To update an aria value or any property of the hidden dom element use the AccessibleNode.update_property method:
```gdscript
extends Button

@onready var accessible_node = GodotAria.get_accesible_node(self)

# By default Label and RichText label are exposed with the 'paragraph' role
var aria_label = "An accessible name" :
  set(value):
    aria_label = value
    accessible_node.update_property("ariaLabel", value)
```

### Examples

Custom label:
```gdscript
extends Button

# By default the text property will be used as a label 
var aria_label = "Action"
```

Prevents this plugin from exposing a Control node by default:
```gdscript
extends Button

var aria_hidden = true
```

Custom role:
```gdscript
extends Label

# By default Label and RichText label are exposed with the 'paragraph' role
var aria_role = "heading"
var aria_level = 1
```

### Additional utilities
Use the global class `GodotARIA` to call utility functions. 

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
### GodotARIA.get_accessible_node
Retrives the AccessibleNode of a control exposed to the accesibility tree.
You can use this to interact or update the hidden dom element associated with the target control.
```py
GodotARIA.get_accessible_node(target: Control) -> AccessibleNode
```

### GodotARIA.notify_screen_reader
Awaits for a natural pause before speaking up. It won’t interrupt what the screen reader is currently announcing. Equivalent to aria-live [polite](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-live#polite).

If the reannounce value is set to true the screen reader can repeat the previous message otherwise no update will occur until the message changes.

If no lang value is passed it will use the current locale from the [TranslationServer](https://docs.godotengine.org/en/4.3/classes/class_translationserver.html#class-translationserver-method-get-locale).
```py
  GodotARIA.notify_screen_reader(message: String, reannounce: bool = false, lang : String = TranslationServer.get_locale())
```

### GodotARIA.alert_screen_reader
Speak an alert, interrupts whatever the screen reader is currently announcing. Equivalent to aria-live [assertive](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-live#assertive).

If the reannounce value is set to true the screen reader can repeat the previous message otherwise no update will occur until the message changes.

If no lang value is passed it will use the current locale from the [TranslationServer](https://docs.godotengine.org/en/4.3/classes/class_translationserver.html#class-translationserver-method-get-locale).
```py
  GodotARIA.alert_screen_reader(message: String, reannounce: bool = false, lang : String = TranslationServer.get_locale())
```

### GodotARIA.get_media_feature
Detects and returns a [media feature](https://developer.mozilla.org/en-US/docs/Web/CSS/@media#media_features) value. 

```py
  GodotARIA.get_media_feature(feature: String)
```

Supported feature values:
- prefers-color-scheme: Detect if the user prefers a light or dark color scheme.
- prefers-contrast: Detects if the user has requested the system increase or decrease the amount of contrast between adjacent colors. 
- prefers-reduced-motion: The user prefers less motion on the page.
- prefers-reduced-transparency: Detects if a user has enabled a setting on their device to reduce the transparent or translucent layer effects used on the device.
