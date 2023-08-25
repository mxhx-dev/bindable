# Bindable

A data binding library for [Haxe](https://haxe.org/) and [MXHX](https://mxhx.dev/).

## Minimum Requirements

- Haxe 4.0

## Installation

This library is not yet available on Haxelib, so you'll need to install it from Github.

```sh
haxelib git bindable https://github.com/mxhx-dev/bindable.git
```

## Project Configuration

## OpenFL

After installing the library above, add it to your Haxe _.hxml_ file.

```hxml
--library bindable
```

For Lime and OpenFL, add it to your _project.xml_ file.

```xml
<haxelib name="bindable" />
```

## Usage

The first argument is the source of the data. The second is the destination. The final argument is a display object where the binding should be activated when it is added to the stage, and deactivated when it is removed.

```hx
DataBinding.bind(Std.string(slider.value), label.text, this);
```
