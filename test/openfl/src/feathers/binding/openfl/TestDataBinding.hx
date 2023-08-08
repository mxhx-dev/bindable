/*
	feathersui-binding
	Copyright 2023 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.binding.openfl;

import feathers.binding.openfl.fixtures.ClassWithRegularMethod;
import feathers.binding.openfl.fixtures.ClassWithRegularProperty;
import feathers.binding.openfl.fixtures.ClassWithBindableDynamicProperty;
import feathers.binding.openfl.fixtures.ClassWithBindableMethod;
import feathers.binding.openfl.fixtures.ClassWithBindableProperty;
import feathers.binding.openfl.fixtures.ClassWithNestedBindableProperty;
import feathers.binding.openfl.fixtures.SubclassWithBindableMethod;
import feathers.binding.openfl.fixtures.SubclassWithBindableProperty;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import utest.Assert;
import utest.Test;

class TestDataBinding extends Test {
	private var document:Sprite;

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

	public function testRegularProperty():Void {
		final firstValue = "hello";
		final secondValue = "goodbye";
		var bindToMe:String = null;
		var instance = new ClassWithRegularProperty();
		instance.regularProp = firstValue;
		DataBinding.bind(instance.regularProp, bindToMe, document);
		// binding should apply original value instantly
		Assert.equals(firstValue, bindToMe);
		instance.regularProp = secondValue;
		// since :bindable is missing, nothing is detected
		Assert.equals(firstValue, bindToMe);
	}

	public function testRegularMethod():Void {
		var bindToMe:Int = -1;
		var instance = new ClassWithRegularMethod();
		DataBinding.bind(instance.regularMethod(), bindToMe, document);
		// binding should apply original value instantly
		Assert.equals(1, bindToMe);
		instance.dispatchEvent(new Event(Event.CHANGE));
		// since :bindable is missing, nothing is detected
		Assert.equals(1, bindToMe);
	}

	public function testBindableProperty():Void {
		final firstValue = "hello";
		final secondValue = "goodbye";
		var bindToMe:String = null;
		var instance = new ClassWithBindableProperty();
		instance.bindableProp = firstValue;
		DataBinding.bind(instance.bindableProp, bindToMe, document);
		// binding should apply original value instantly
		Assert.equals(firstValue, bindToMe);
		instance.bindableProp = secondValue;
		// binding should detect :bindable meta with change event
		Assert.equals(secondValue, bindToMe);
	}

	public function testNestedBindableProperty1():Void {
		final firstValue = "hello";
		final secondValue = "goodbye";
		var bindToMe:String = null;
		var instance = new ClassWithNestedBindableProperty();
		instance.outerBindableProp.bindableProp = firstValue;
		DataBinding.bind(instance.outerBindableProp.bindableProp, bindToMe, document);
		// binding should apply original value instantly
		Assert.equals(firstValue, bindToMe);
		instance.outerBindableProp.bindableProp = secondValue;
		// binding should detect :bindable meta with change event
		Assert.equals(secondValue, bindToMe);
	}

	public function testNestedBindableProperty2():Void {
		final firstValue = "hello";
		final secondValue = "goodbye";
		var bindToMe:String = null;
		var instance = new ClassWithNestedBindableProperty();
		instance.outerBindableProp.bindableProp = firstValue;
		DataBinding.bind(instance.outerBindableProp.bindableProp, bindToMe, document);
		// binding should apply original value instantly
		Assert.equals(firstValue, bindToMe);
		instance.outerBindableProp = new ClassWithBindableProperty(secondValue);
		// binding should detect :bindable meta with change event
		Assert.equals(secondValue, bindToMe);
	}

	public function testBindableMethod():Void {
		var bindToMe:Int = -1;
		var instance = new ClassWithBindableMethod();
		DataBinding.bind(instance.bindableMethod(), bindToMe, document);
		// binding should apply original value instantly
		Assert.equals(1, bindToMe);
		instance.dispatchEvent(new Event(Event.CHANGE));
		Assert.equals(2, bindToMe);
	}

	public function testMissingFieldException1():Void {
		final originalText = "original";
		final newText = "new";
		var bindToMe = originalText;
		var instance = new ClassWithBindableDynamicProperty();
		DataBinding.bind(instance.bindableDynamicProp.hello, bindToMe, document);
		// binding should not change value if exception is thrown
		Assert.equals(originalText, bindToMe);
		instance.bindableDynamicProp = {hello: newText};
		Assert.equals(newText, bindToMe);
	}

	public function testMissingFieldException2():Void {
		final originalText = "original";
		final newText = "new";
		var bindToMe = originalText;
		var instance = new ClassWithNestedBindableProperty();
		instance.outerBindableProp = null;
		DataBinding.bind(instance.outerBindableProp.bindableProp, bindToMe, document);
		// binding should not change value if exception is thrown
		Assert.equals(originalText, bindToMe);
		instance.outerBindableProp = new ClassWithBindableProperty(newText);
		Assert.equals(newText, bindToMe);
	}

	public function testSubclassBindableProperty():Void {
		final firstValue = "hello";
		final secondValue = "goodbye";
		var bindToMe:String = null;
		var instance = new SubclassWithBindableProperty();
		instance.bindableProp = firstValue;
		DataBinding.bind(instance.bindableProp, bindToMe, document);
		Assert.equals(firstValue, bindToMe);
		instance.bindableProp = secondValue;
		// ensures that :bindable metadata is detected on superclass
		Assert.equals(secondValue, bindToMe);
	}

	public function testSubclassBindableMethod():Void {
		var bindToMe:Int = -1;
		var instance = new SubclassWithBindableMethod();
		DataBinding.bind(instance.bindableMethod(), bindToMe, document);
		Assert.equals(1, bindToMe);
		instance.dispatchEvent(new Event(Event.CHANGE));
		// ensures that :bindable metadata is detected on superclass
		Assert.equals(2, bindToMe);
	}
}
