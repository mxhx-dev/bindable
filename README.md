# Data Binding for Feathers UI

A data binding library for [Feathers UI](https://feathersui.com/).

## Installation

This library is not yet available on Haxelib, so you'll need to install it from Github.

```sh
haxelib git feathersui-binding https://github.com/feathersui/feathersui-binding.git
```

## Project Configuration

After installing the libraries above, add them to your OpenFL _project.xml_ file:

```xml
<haxelib name="feathersui-binding" />
```

## Usage

The first argument is the source of the data. The second is the destination. The final argument is a display object where the binding should be activated when it is added to the stage, and deactivated when it is removed.

```hx
DataBinding.bind(slider.value, label.text, this);
```

## Documentation

- [API Reference](https://api.feathersui.com/feathersui-binding/)
