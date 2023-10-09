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

After installing the library above, add it to your Haxe _.hxml_ file.

```hxml
--library bindable
```

### OpenFL or Lime

For Lime and OpenFL, add it to your _project.xml_ file instead.

```xml
<haxelib name="bindable" />
```

## Usage

The first argument is the source of the data. The second is the destination. The final argument is a display object where the binding should be activated when it is added to the stage, and deactivated when it is removed.

```hx
DataBinding.bind(Std.string(slider.value), label.text, this);
```

### C++

When Haxe creates a release build for the _cpp_ target, it omits certain null checks by default. This configuration can lead to segmentation faults when accessing fields on `null` objects, instead of an exception that can be caught, like other targets.

There are a couple of different ways to workaround this quirk.

1. Adding the `HXCPP_CHECK_POINTER` define to your project's configuration to enable the missing `null` checks.

2. If using Haxe 4.3 or newer, using the _safe navigation operator_ to manually handle `null` objects.

   ```haxe
   DataBinding.bind(obj?.prop, dest, this);
   ```
