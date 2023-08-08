/*
	feathersui-binding
	Copyright 2023 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.binding;

class BasicPropertyWatcher implements IPropertyWatcher {
	public function new(propertyGetter:() -> Dynamic, listener:(Dynamic) -> Void) {
		_propertyGetter = propertyGetter;
		_listener = listener;
	}

	public var value(default, null):Dynamic = null;

	private var _propertyGetter:() -> Dynamic;
	private var _listener:(Dynamic) -> Void;
	private var _parentObject:Dynamic;
	private var _parentWatcher:IPropertyWatcher;
	private var _children:Array<IPropertyWatcher>;
	private var _exception:Bool = false;

	public function updateParentObject(object:Dynamic):Void {
		_parentWatcher = null;
		_parentObject = object;
		updateValue();
	}

	public function updateParentWatcher(watcher:IPropertyWatcher):Void {
		_parentWatcher = watcher;
		_parentObject = null;
		if (_parentWatcher != null) {
			_parentObject = _parentWatcher.value;
		}
		updateValue();
	}

	public function notifyListener():Void {
		if (_listener == null || _exception) {
			return;
		}
		_listener(value);
	}

	public function addChild(child:IPropertyWatcher):Void {
		if (_children == null) {
			_children = [];
		}
		_children.push(child);
		child.updateParentWatcher(this);
	}

	public function removeChildren():Void {
		if (_children == null) {
			return;
		}
		for (child in _children) {
			child.updateParentWatcher(null);
		}
		_children = null;
	}

	private function updateValue():Void {
		_exception = false;
		if (_parentObject == null) {
			value = null;
		} else {
			try {
				value = _propertyGetter();
			} catch (e:Dynamic) {
				_exception = true;
			}
		}
		updateChildren();
	}

	private function updateChildren():Void {
		if (_children == null) {
			return;
		}

		for (child in _children) {
			child.updateParentWatcher(this);
		}
	}
}
