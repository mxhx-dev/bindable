/*
	feathersui-binding
	Copyright 2023 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.binding.openfl.fixtures;

import openfl.events.Event;
import openfl.events.EventDispatcher;

class ClassWithBindableDynamicProperty extends EventDispatcher {
	public function new() {
		super();
	}

	@:bindable("change")
	public var bindableDynamicProp(default, set):Dynamic;

	private function set_bindableDynamicProp(value:Dynamic):Dynamic {
		if (bindableDynamicProp == value) {
			return bindableDynamicProp;
		}
		bindableDynamicProp = value;
		dispatchEvent(new Event(Event.CHANGE));
		return bindableDynamicProp;
	}
}