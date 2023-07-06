package feathers.binding;

class PropertyWatcherBinding {
	private var _watchers:Array<PropertyWatcher>;
	private var _rootWatcher:PropertyWatcher;
	private var _parentObject:Any;

	public var active(default, null):Bool = false;

	public function new(watchers:Array<PropertyWatcher>, parentObject:Any) {
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
