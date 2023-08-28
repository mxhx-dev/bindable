/*
	Bindable
	Copyright 2023 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package mxhx.bindable.openfl.fixtures;

import openfl.events.Event;
import openfl.events.EventDispatcher;

class ClassWithNestedBindableProperty extends EventDispatcher {
	public function new() {
		super();
	}

	@:bindable("change")
	public var outerBindableProp(default, set):ClassWithBindableProperty = new ClassWithBindableProperty();

	private function set_outerBindableProp(value:ClassWithBindableProperty):ClassWithBindableProperty {
		if (outerBindableProp == value) {
			return outerBindableProp;
		}
		outerBindableProp = value;
		dispatchEvent(new Event(Event.CHANGE));
		return outerBindableProp;
	}
}
