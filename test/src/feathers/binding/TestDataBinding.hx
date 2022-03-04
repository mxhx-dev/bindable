/*
	Feathers UI
	Copyright 2022 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.binding;

import openfl.Lib;
import openfl.display.Sprite;
import utest.Assert;
import utest.Test;

class TestDataBinding extends Test {
	private static final STATIC_STRING_VALUE = "static";

	private final MEMBER_STRING_VALUE = "member";

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

	public function testBindLocalFinal():Void {
		final LOCAL_STRING_VALUE = "hi there";
		var s = "";
		// a compiler warning is expected because there doesn't seem to be
		// a way to detect that a local var is final or not
		DataBinding.bind(LOCAL_STRING_VALUE, s, document);
		Assert.equals(LOCAL_STRING_VALUE, s);
	}

	public function testBindUnqualifiedStaticFinal():Void {
		var s = "";
		DataBinding.bind(STATIC_STRING_VALUE, s, document);
		Assert.equals(STATIC_STRING_VALUE, s);
	}

	public function testBindQualifiedStaticFinal():Void {
		var s = "";
		DataBinding.bind(TestDataBinding.STATIC_STRING_VALUE, s, document);
		Assert.equals(STATIC_STRING_VALUE, s);
	}

	public function testBindUnqualifiedMemberFinal():Void {
		var s = "";
		DataBinding.bind(MEMBER_STRING_VALUE, s, document);
		Assert.equals(MEMBER_STRING_VALUE, s);
	}

	public function testBindQualifiedMemberFinal():Void {
		var s = "";
		DataBinding.bind(this.MEMBER_STRING_VALUE, s, document);
		Assert.equals(MEMBER_STRING_VALUE, s);
	}
}
