package feathers.binding;

interface IPropertyWatcher {
	var value(default, never):Dynamic;
	function updateParentObject(object:Dynamic):Void;
	function updateParentWatcher(watcher:IPropertyWatcher):Void;
	function notifyListener():Void;
	function addChild(child:IPropertyWatcher):Void;
	function removeChildren():Void;
}
