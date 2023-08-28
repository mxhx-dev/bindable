/*
	Bindable
	Copyright 2023 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package mxhx.bindable;

class PropertyWatcherBinding {
	private var _watchers:Array<IPropertyWatcher>;
	private var _rootWatcher:IPropertyWatcher;
	private var _parentObject:Any;

	public var active(default, null):Bool = false;

	public function new(watchers:Array<IPropertyWatcher>, parentObject:Any) {
		_watchers = watchers;
		_rootWatcher = _watchers[0];
		_parentObject = parentObject;
	}

	public function activate():Void {
		if (active) {
			return;
		}
		active = true;
		_rootWatcher.updateParentObject(_parentObject);
	}

	public function deactivate():Void {
		if (!active) {
			return;
		}
		active = false;
		_rootWatcher.updateParentObject(null);
	}
}
