/*
	Bindable
	Copyright 2023 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package mxhx.bindable;

import utest.Assert;
import utest.Test;

class TestBasicPropertyWatcher extends Test {
	private var watcher:BasicPropertyWatcher;

	public function new() {
		super();
	}

	public function setup():Void {}

	public function teardown():Void {}

	public function testUpdateParentObject():Void {
		final expectedResult = "hello";
		watcher = new BasicPropertyWatcher(() -> expectedResult, null);
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
		watcher = new BasicPropertyWatcher(() -> expectedResult, null);
		// value should always be null before updating parent watcher
		Assert.isNull(watcher.value);
		var parentWatcher = new BasicPropertyWatcher(() -> {
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

	public function testUpdateProp():Void {
		final firstValue = "hello";
		final secondValue = "goodbye";
		var bindToMe:String = null;
		var instance = new ClassWithBindableProperty();
		instance.bindableProp = firstValue;
		watcher = new BasicPropertyWatcher(() -> instance.bindableProp, result -> bindToMe = result);
		// binding should not propagate until after parent object is updated
		Assert.isNull(bindToMe);
		watcher.updateParentObject(instance);
		watcher.notifyListener();
		Assert.equals(firstValue, bindToMe);
		instance.bindableProp = secondValue;
		watcher.updateParentObject(instance);
		watcher.notifyListener();
		Assert.equals(secondValue, bindToMe);
	}

	public function testNestedUpdateProp1():Void {
		final firstValue = "hello";
		final secondValue = "goodbye";
		var bindToMe:String = null;
		var instance = new ClassWithNestedBindableProperty();
		instance.outerBindableProp.bindableProp = firstValue;
		watcher = new BasicPropertyWatcher(() -> instance.outerBindableProp, result -> {
			bindToMe = instance.outerBindableProp.bindableProp;
		});
		var watcher2 = new BasicPropertyWatcher(() -> instance.outerBindableProp.bindableProp, result -> {
			bindToMe = instance.outerBindableProp.bindableProp;
		});
		watcher.addChild(watcher2);
		// binding should not propagate until after parent object is updated
		Assert.isNull(bindToMe);
		watcher.updateParentObject(instance);
		watcher.notifyListener();
		Assert.equals(firstValue, bindToMe);
		instance.outerBindableProp.bindableProp = secondValue;
		watcher.updateParentObject(instance);
		watcher.notifyListener();
		Assert.equals(secondValue, bindToMe);
	}

	public function testNestedUpdateProp2():Void {
		final firstValue = "hello";
		final secondValue = "goodbye";
		var bindToMe:String = null;
		var instance = new ClassWithNestedBindableProperty();
		instance.outerBindableProp.bindableProp = firstValue;
		watcher = new BasicPropertyWatcher(() -> instance.outerBindableProp, result -> {
			bindToMe = instance.outerBindableProp.bindableProp;
		});
		var watcher2 = new BasicPropertyWatcher(() -> instance.outerBindableProp.bindableProp, result -> {
			bindToMe = instance.outerBindableProp.bindableProp;
		});
		watcher.addChild(watcher2);
		// binding should not propagate until after parent object is updated
		Assert.isNull(bindToMe);
		watcher.updateParentObject(instance);
		watcher.notifyListener();
		Assert.equals(firstValue, bindToMe);
		instance.outerBindableProp = new ClassWithBindableProperty(secondValue);
		watcher.updateParentObject(instance);
		watcher.notifyListener();
		Assert.equals(secondValue, bindToMe);
	}

	public function testBindableMethod():Void {
		var bindToMe:Int = -1;
		var instance = new ClassWithBindableMethod();
		watcher = new BasicPropertyWatcher(() -> instance.bindableMethod(), result -> bindToMe = result);
		// binding should not propagate until after parent object is updated
		Assert.equals(-1, bindToMe);
		watcher.updateParentObject(instance);
		watcher.notifyListener();
		Assert.equals(1, bindToMe);
		watcher.updateParentObject(instance);
		watcher.notifyListener();
		Assert.equals(2, bindToMe);
	}

	#if (!cpp || HXCPP_CHECK_POINTER)
	public function testMissingFieldException():Void {
		final originalText = "original";
		final newText = "new";
		var bindToMe = originalText;
		var instance = new ClassWithBindableDynamicProperty();
		watcher = new BasicPropertyWatcher(() -> instance.bindableDynamicProp.hello, result -> bindToMe = result);
		// binding should not propagate until after parent object is updated
		Assert.equals(originalText, bindToMe);
		watcher.updateParentObject(instance);
		watcher.notifyListener();
		#if interp
		// Haxe interpreter doesn't seem to throw exception when bindableDynamicProp is null
		Assert.isNull(bindToMe);
		#else
		// binding should not change value if exception is thrown
		Assert.equals(originalText, bindToMe);
		#end
		instance.bindableDynamicProp = {hello: newText};
		watcher.updateParentObject(instance);
		watcher.notifyListener();
		Assert.equals(newText, bindToMe);
	}
	#end

	#if (haxe_ver >= 4.3)
	public function testMissingFieldWithSafeNavigationOperator():Void {
		final originalText = "original";
		final newText = "new";
		var bindToMe = originalText;
		var instance = new ClassWithBindableDynamicProperty();
		watcher = new BasicPropertyWatcher(() -> instance?.bindableDynamicProp?.hello, result -> bindToMe = result);
		// binding should not propagate until after parent object is updated
		Assert.equals(originalText, bindToMe);
		watcher.updateParentObject(instance);
		watcher.notifyListener();
		Assert.isNull(bindToMe);
		instance.bindableDynamicProp = {hello: newText};
		watcher.updateParentObject(instance);
		watcher.notifyListener();
		Assert.equals(newText, bindToMe);
	}
	#end
}

private class ClassWithBindableProperty {
	public function new(?value:String) {
		bindableProp = value;
	}

	@:bindable("change")
	public var bindableProp(default, set):String;

	private function set_bindableProp(value:String):String {
		if (bindableProp == value) {
			return bindableProp;
		}
		bindableProp = value;
		return bindableProp;
	}
}

private class ClassWithNestedBindableProperty {
	public function new() {}

	@:bindable("change")
	public var outerBindableProp(default, set):ClassWithBindableProperty = new ClassWithBindableProperty();

	private function set_outerBindableProp(value:ClassWithBindableProperty):ClassWithBindableProperty {
		if (outerBindableProp == value) {
			return outerBindableProp;
		}
		outerBindableProp = value;
		return outerBindableProp;
	}
}

private class ClassWithBindableMethod {
	public function new() {}

	@:bindable("change")
	public function bindableMethod():Int {
		count++;
		return count;
	}

	private var count:Int = 0;
}

private class ClassWithBindableDynamicProperty {
	public function new() {}

	@:bindable("change")
	public var bindableDynamicProp(default, set):Dynamic;

	private function set_bindableDynamicProp(value:Dynamic):Dynamic {
		if (bindableDynamicProp == value) {
			return bindableDynamicProp;
		}
		bindableDynamicProp = value;
		return bindableDynamicProp;
	}
}
