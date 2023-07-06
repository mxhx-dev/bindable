/*
	Feathers UI
	Copyright 2023 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.binding.openfl;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import utest.Assert;
import utest.Test;

class TestPropertyWatcher extends Test {
	private var document:Sprite;
	private var watcher:PropertyWatcher;

	public function new() {
		super();
	}

	public function setup():Void {
		document = new Sprite();
		Lib.current.addChild(document);
	}

	public function teardown():Void {
		if (document.parent != null) {
			document.parent.removeChild(document);
		}
		document = null;
		Assert.equals(1, Lib.current.numChildren, "Test cleanup failed to remove all children from the root");
	}

	public function testUpdateParentObject():Void {
		final expectedResult = "hello";
		watcher = new PropertyWatcher(Event.CHANGE, () -> expectedResult, null);
		// value should always be null before updating parent object
		Assert.isNull(watcher.value);
		watcher.updateParentObject({});
		Assert.equals(expectedResult, watcher.value);
		watcher.updateParentObject(null);
		// value should always be null after setting parent object to null
		Assert.isNull(watcher.value);
	}

	public function testUpdateParentWatcher():Void {
		final expectedResult = "hello";
		watcher = new PropertyWatcher(Event.CHANGE, () -> expectedResult, null);
		// value should always be null before updating parent watcher
		Assert.isNull(watcher.value);
		var parentWatcher = new PropertyWatcher(Event.CHANGE, () -> {
			return {};
		}, null);
		parentWatcher.updateParentObject({});
		watcher.updateParentWatcher(parentWatcher);
		Assert.equals(expectedResult, watcher.value);
		watcher.updateParentWatcher(null);
		// value should always be null after setting parent watcher to null
		Assert.isNull(watcher.value);
		parentWatcher.updateParentObject(null);
	}

	public function testBindableEvent():Void {
		final firstValue = "hello";
		final secondValue = "goodbye";
		var bindToMe:String = null;
		var instance = new ClassWithBindableProperty();
		instance.bindableProp = firstValue;
		watcher = new PropertyWatcher(Event.CHANGE, () -> instance.bindableProp, result -> bindToMe = result);
		// binding should not propagation until after parent object is updated
		Assert.isNull(bindToMe);
		watcher.updateParentObject(instance);
		watcher.notifyListener();
		Assert.equals(firstValue, bindToMe);
		instance.bindableProp = secondValue;
		Assert.equals(secondValue, bindToMe);
	}

	public function testNestedBindableEvent1():Void {
		final firstValue = "hello";
		final secondValue = "goodbye";
		var bindToMe:String = null;
		var instance = new ClassWithNestedBindableProperty();
		instance.outerBindableProp.bindableProp = firstValue;
		watcher = new PropertyWatcher(Event.CHANGE, () -> instance.outerBindableProp, result -> {
			bindToMe = instance.outerBindableProp.bindableProp;
		});
		var watcher2 = new PropertyWatcher(Event.CHANGE, () -> instance.outerBindableProp.bindableProp, result -> {
			bindToMe = instance.outerBindableProp.bindableProp;
		});
		watcher.addChild(watcher2);
		// binding should not propagation until after parent object is updated
		Assert.isNull(bindToMe);
		watcher.updateParentObject(instance);
		watcher.notifyListener();
		Assert.equals(firstValue, bindToMe);
		instance.outerBindableProp.bindableProp = secondValue;
		Assert.equals(secondValue, bindToMe);
	}

	public function testNestedBindableEvent2():Void {
		final firstValue = "hello";
		final secondValue = "goodbye";
		var bindToMe:String = null;
		var instance = new ClassWithNestedBindableProperty();
		instance.outerBindableProp.bindableProp = firstValue;
		watcher = new PropertyWatcher(Event.CHANGE, () -> instance.outerBindableProp, result -> {
			bindToMe = instance.outerBindableProp.bindableProp;
		});
		var watcher2 = new PropertyWatcher(Event.CHANGE, () -> instance.outerBindableProp.bindableProp, result -> {
			bindToMe = instance.outerBindableProp.bindableProp;
		});
		watcher.addChild(watcher2);
		// binding should not propagation until after parent object is updated
		Assert.isNull(bindToMe);
		watcher.updateParentObject(instance);
		watcher.notifyListener();
		Assert.equals(firstValue, bindToMe);
		instance.outerBindableProp = new ClassWithBindableProperty(secondValue);
		Assert.equals(secondValue, bindToMe);
	}

	public function testBindableMethod():Void {
		var bindToMe:Int = -1;

		var instance = new ClassWithBindableMethod();
		watcher = new PropertyWatcher(Event.CHANGE, () -> instance.bindableMethod(), result -> bindToMe = result);
		// binding should not propagation until after parent object is updated
		Assert.equals(-1, bindToMe);
		watcher.updateParentObject(instance);
		watcher.notifyListener();
		Assert.equals(1, bindToMe);
		instance.dispatchEvent(new Event(Event.CHANGE));
		Assert.equals(2, bindToMe);
	}
}

private class ClassWithBindableProperty extends EventDispatcher {
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

private class ClassWithNestedBindableProperty extends EventDispatcher {
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

private class ClassWithBindableMethod extends EventDispatcher {
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
