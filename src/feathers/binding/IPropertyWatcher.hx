/*
	Bindable
	Copyright 2023 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.binding;

interface IPropertyWatcher {
	var value(default, never):Dynamic;
	function updateParentObject(object:Dynamic):Void;
	function updateParentWatcher(watcher:IPropertyWatcher):Void;
	function notifyListener():Void;
	function addChild(child:IPropertyWatcher):Void;
	function removeChildren():Void;
}
