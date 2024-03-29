/*
	Bindable
	Copyright 2023 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package mxhx.bindable.openfl;

import openfl.events.Event;
import openfl.events.IEventDispatcher;

class PropertyWatcher implements IPropertyWatcher {
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
	private var _parentWatcher:IPropertyWatcher;
	private var _children:Array<IPropertyWatcher>;
	private var _exception:Bool = false;

	public function updateParentObject(object:Dynamic):Void {
		removeChangeEventListener();
		_parentWatcher = null;
		_parentObject = object;
		addChangeEventListener();
		updateValue();
	}

	public function updateParentWatcher(watcher:IPropertyWatcher):Void {
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

	private function addChangeEventListener():Void {
		if (_changeEvent == null || _parentObject == null || !(_parentObject is IEventDispatcher)) {
			return;
		}
		var parentDispatcher = (_parentObject : IEventDispatcher);
		// must not use weak listener because there may not be another strong
		// reference to a GC root.
		parentDispatcher.addEventListener(_changeEvent, propertyWatcher_changeHandler, false, 100);
	}

	private function removeChangeEventListener():Void {
		if (_changeEvent == null || _parentObject == null || !(_parentObject is IEventDispatcher)) {
			return;
		}
		var parentDispatcher = (_parentObject : IEventDispatcher);
		parentDispatcher.removeEventListener(_changeEvent, propertyWatcher_changeHandler);
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

	private function propertyWatcher_changeHandler(event:Event):Void {
		updateValue();
		notifyListener();
	}
}
