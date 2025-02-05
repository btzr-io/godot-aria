> [!note]
> Experimental plugin, feel free to contribute or report any issues to improve compatibility with more web browsers and screen readers.

# Godot-ARIA
A plugin for creating accessible rich internet applications with godot.

### Features
- Accessible html page template.
- Notifiy changes or important alerts to screen readers.
- Expose Control nodes to the browser accesibility tree.
- Media features detection (reduce motion, contrast preferences, light / dark theme)
- Restore or gain focus with tab / shift + tab navigation.
- Focus can leave the canvas element to navigate other content on the web page.
- Native html text input element as an hybrid control node ( replacement for LineEdit control )

### Current screen reader support:
- NVDA works consintently well across all major browsers ( Chrome based and Firefox ).  
- JAWS screen reader with Google chrome or similar browsers (Brave, Edge, Opera).

### Planned support:
- ORCA for linux
- Voice over for MacOs
  
## Installation
Just add the addons folder to your project and enable the plugin or install from the godot [assets library](https://godotengine.org/asset-library/asset/3584).

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

### Aria variables
Text content and some interactive controls will be automatically exposed to the accesibility tree as hidden dom elements with aria role and attributes:
- Button -> 'button'
- Checkbox -> 'checkbox'
- Checkbutton -> 'switch'
- Label and RichTextLabel -> 'paragraph'
- Progressbar -> 'progressbar'
- Slider -> 'slider'

Declaring aria_* prefixed variables indside a control node will add or overwrite the initial value of an aria attribute of the hidden dom element.
For more information about aria attributes please read the 

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

Expose a non interactive Control node:
```gdscript
extends Container

# Declaring a valid aria role will expose the control to the accesibility tree
var aria_role = "region"
var aria_label = "The region name..."
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

### GodotARIA.notify_screen_reader
Awaits for a natural pause before speaking up. It won’t interrupt what the screen reader is currently announcing. Equivalent to aria-live [polite](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-live#polite).

If no lang value is passed it will use the current locale from the [TranslationServer](https://docs.godotengine.org/en/4.3/classes/class_translationserver.html#class-translationserver-method-get-locale).
```py
  GodotARIA.notify_screen_reader(message: String, lang : String = TranslationServer.get_locale())
```

### GodotARIA.alert_screen_reader
Speak an alert, interrupts whatever the screen reader is currently announcing. Equivalent to aria-live [assertive](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-live#assertive).

If no lang value is passed it will use the current locale from the [TranslationServer](https://docs.godotengine.org/en/4.3/classes/class_translationserver.html#class-translationserver-method-get-locale).
```py
  GodotARIA.alert_screen_reader(message: String, lang : String = TranslationServer.get_locale())
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
