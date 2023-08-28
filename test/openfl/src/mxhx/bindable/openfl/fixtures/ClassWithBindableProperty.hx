/*
	Bindable
	Copyright 2023 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package mxhx.bindable.openfl.fixtures;

import openfl.events.Event;
import openfl.events.EventDispatcher;

class ClassWithBindableProperty extends EventDispatcher {
	public function new(?value:String) {
		super();
		bindableProp = value;
	}

	@:bindable("change")
	public var bindableProp(default, set):String;

	private function set_bindableProp(value:String):String {
		if (bindableProp == value) {
			return bindableProp;
		}
		bindableProp = value;
		dispatchEvent(new Event(Event.CHANGE));
		return bindableProp;
	}
}
