/*
	feathersui-binding
	Copyright 2023 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.binding;

import openfl.events.Event;
import openfl.events.IEventDispatcher;

class PropertyWatcher {
	public function new(changeEvent:String, propertyGetter:() -> Dynamic, listener:(Dynamic) -> Void) {
		_changeEvent = changeEvent;
		_propertyGetter = propertyGetter;
		_listener = listener;
	}

	public var value(default, null):Dynamic = null;

	private var _propertyGetter:() -> Dynamic;
	private var _listener:(Dynamic) -> Void;
	private var _changeEvent:String;
	private var _parentObject:Dynamic;
	private var _parentWatcher:PropertyWatcher;
	private var _children:Array<PropertyWatcher>;

	public function updateParentObject(object:Dynamic):Void {
		removeChangeEventListener();
		_parentWatcher = null;
		_parentObject = object;
		addChangeEventListener();
		updateValue();
	}

	public function updateParentWatcher(watcher:PropertyWatcher):Void {
		removeChangeEventListener();
		_parentWatcher = watcher;
		_parentObject = null;
		if (_parentWatcher != null) {
			_parentObject = _parentWatcher.value;
		}
		addChangeEventListener();
		updateValue();
	}

	public function notifyListener():Void {
		if (_listener == null) {
			return;
		}
		_listener(value);
	}

	public function addChild(child:PropertyWatcher):Void {
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

	private function addChangeEventListener():Void {
		if (_changeEvent == null || _parentObject == null || !(_parentObject is IEventDispatcher)) {
			return;
		}
		var parentDispatcher = (_parentObject : IEventDispatcher);
		parentDispatcher.addEventListener(_changeEvent, propertyWatcher_changeHandler, false, 100, true);
	}

	private function removeChangeEventListener():Void {
		if (_changeEvent == null || _parentObject == null || !(_parentObject is IEventDispatcher)) {
			return;
		}
		var parentDispatcher = (_parentObject : IEventDispatcher);
		parentDispatcher.removeEventListener(_changeEvent, propertyWatcher_changeHandler);
	}

	private function updateValue():Void {
		if (_parentObject == null) {
			value = null;
		} else {
			try {
				value = _propertyGetter();
			} catch (e:Dynamic) {}
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

	private function propertyWatcher_changeHandler(event:Event):Void {
		updateValue();
		notifyListener();
	}
}
