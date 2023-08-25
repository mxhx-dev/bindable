/*
	Bindable
	Copyright 2023 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.binding.openfl.fixtures;

import openfl.events.EventDispatcher;

class ClassWithBindableMethod extends EventDispatcher {
	public function new() {
		super();
	}

	@:bindable("change")
	public function bindableMethod():Int {
		count++;
		return count;
	}

	private var count:Int = 0;
}
