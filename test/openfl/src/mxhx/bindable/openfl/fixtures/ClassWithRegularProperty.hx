/*
	Bindable
	Copyright 2023 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package mxhx.bindable.openfl.fixtures;

import openfl.events.Event;
import openfl.events.EventDispatcher;

class ClassWithRegularProperty extends EventDispatcher {
	public function new(?value:String) {
		super();
		regularProp = value;
	}

	// no :bindable
	public var regularProp(default, set):String;

	private function set_regularProp(value:String):String {
		if (regularProp == value) {
			return regularProp;
		}
		regularProp = value;
		dispatchEvent(new Event(Event.CHANGE));
		return regularProp;
	}
}
