/*
	feathersui-binding
	Copyright 2022 Bowler Hat LLC. All Rights Reserved.

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

	public function updateParentObject(object:Dynamic):Void {
		removeChangeEventListener();
		_parentObject = object;
		addChangeEventListener();
		updateValue();
	}

	public function notifyListener():Void {
		_listener(value);
	}

	private function addChangeEventListener():Void {
		if (_parentObject == null) {
			return;
		}
		if (!(_parentObject is IEventDispatcher)) {
			return;
		}
		var parentDispatcher = (_parentObject : IEventDispatcher);
		parentDispatcher.addEventListener(_changeEvent, propertyWatcher_changeHandler, false, 100, true);
	}

	private function removeChangeEventListener():Void {
		if (_parentObject == null) {
			return;
		}
		if (!(_parentObject is IEventDispatcher)) {
			return;
		}
		var parentDispatcher = (_parentObject : IEventDispatcher);
		parentDispatcher.removeEventListener(_changeEvent, propertyWatcher_changeHandler);
	}

	private function updateValue():Void {
		try {
			value = _propertyGetter();
		} catch (e:Dynamic) {}
	}

	private function propertyWatcher_changeHandler(event:Event):Void {
		updateValue();
		notifyListener();
	}
}
