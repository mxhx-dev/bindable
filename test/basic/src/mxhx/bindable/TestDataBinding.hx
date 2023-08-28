/*
	Bindable
	Copyright 2023 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package mxhx.bindable;

import utest.Assert;
import utest.Test;

class TestDataBinding extends Test {
	private static final STATIC_FINAL_STRING = "static";

	private static var staticStringNotBindable:String;

	private static function staticMethodNoArgs():String {
		return "staticMethod";
	}

	private final MEMBER_FINAL_STRING = "member";

	private var memberStringNotBindable:String;

	private function memberMethodNotBindableNoArgs():String {
		return "memberMethod";
	}

	private function memberMethodNotBindableWithArgs(arg1:String, arg2:String):String {
		return arg1 + arg2;
	}

	public function new() {
		super();
	}

	public function setup():Void {
		staticStringNotBindable = "staticStringNotBindable";
		memberStringNotBindable = "memberStringNotBindable";
	}

	public function teardown():Void {}

	public function testBindLocalFinal():Void {
		final LOCAL_FINAL_STRING = "hi there";
		var s = "";
		// a compiler warning is expected because there doesn't seem to be
		// a way to detect from a macro if a local var is final or not
		DataBinding.bind(LOCAL_FINAL_STRING, s);
		Assert.equals(LOCAL_FINAL_STRING, s);
	}

	public function testBindUnqualifiedStaticFinal():Void {
		var s = "";
		DataBinding.bind(STATIC_FINAL_STRING, s);
		Assert.equals(STATIC_FINAL_STRING, s);
	}

	public function testBindQualifiedStaticFinal():Void {
		var s = "";
		DataBinding.bind(TestDataBinding.STATIC_FINAL_STRING, s);
		Assert.equals(STATIC_FINAL_STRING, s);
	}

	public function testBindUnqualifiedMemberFinal():Void {
		var s = "";
		DataBinding.bind(MEMBER_FINAL_STRING, s);
		Assert.equals(MEMBER_FINAL_STRING, s);
	}

	public function testBindQualifiedMemberFinal():Void {
		var s = "";
		DataBinding.bind(this.MEMBER_FINAL_STRING, s);
		Assert.equals(MEMBER_FINAL_STRING, s);
	}

	public function testBindUnqualifiedStaticVar():Void {
		var s = "";
		// a compiler warning is expected because there's no :bindable meta
		DataBinding.bind(staticStringNotBindable, s);
		Assert.equals("staticStringNotBindable", s);
		staticStringNotBindable = "new value";
		Assert.equals("staticStringNotBindable", s);
	}

	public function testBindQualifiedstaticVar():Void {
		var s = "";
		// a compiler warning is expected because there's no :bindable meta
		DataBinding.bind(TestDataBinding.staticStringNotBindable, s);
		Assert.equals("staticStringNotBindable", s);
		staticStringNotBindable = "new value";
		Assert.equals("staticStringNotBindable", s);
	}

	public function testBindUnqualifiedMemberVar():Void {
		var s = "";
		// a compiler warning is expected because there's no :bindable meta
		DataBinding.bind(memberStringNotBindable, s);
		Assert.equals("memberStringNotBindable", s);
		memberStringNotBindable = "new value";
		Assert.equals("memberStringNotBindable", s);
	}

	public function testBindQualifiedMemberVar():Void {
		var s = "";
		// a compiler warning is expected because there's no :bindable meta
		DataBinding.bind(this.memberStringNotBindable, s);
		Assert.equals("memberStringNotBindable", s);
		memberStringNotBindable = "new value";
		Assert.equals("memberStringNotBindable", s);
	}

	public function testBindUnqualifiedMemberMethodNoArgsNotBindable():Void {
		var s = "";
		// a compiler warning is expected because there's no :bindable meta
		DataBinding.bind(memberMethodNotBindableNoArgs(), s);
		Assert.equals(memberMethodNotBindableNoArgs(), s);
	}

	public function testBindQualifiedMemberMethodNoArgsNotBindable():Void {
		var s = "";
		// a compiler warning is expected because there's no :bindable meta
		DataBinding.bind(this.memberMethodNotBindableNoArgs(), s);
		Assert.equals(memberMethodNotBindableNoArgs(), s);
	}

	public function testBindUnqualifiedMemberMethodWithArgsNotBindable():Void {
		var s = "";
		// a compiler warning is expected because there's no :bindable meta
		DataBinding.bind(memberMethodNotBindableWithArgs("one", "two"), s);
		Assert.equals("onetwo", s);
	}

	public function testBindQualifiedMemberMethodWithArgsNotBindable():Void {
		var s = "";
		// a compiler warning is expected because there's no :bindable meta
		DataBinding.bind(this.memberMethodNotBindableWithArgs("one", "two"), s);
		Assert.equals("onetwo", s);
	}

	public function testBindQualifiedMemberMethodWithArgsNotBindable2():Void {
		var s = "";
		// compiler warnings are expected because there's no :bindable meta
		DataBinding.bind(this.memberMethodNotBindableWithArgs(memberStringNotBindable, this.memberStringNotBindable), s);
		Assert.equals("memberStringNotBindablememberStringNotBindable", s);
		memberStringNotBindable = "new value";
		Assert.equals("memberStringNotBindablememberStringNotBindable", s);
	}

	public function testBindQualifiedMemberMethodWithArgsNotBindable3():Void {
		var s = "";
		// compiler warnings are expected because there's no :bindable meta
		DataBinding.bind(this.memberMethodNotBindableWithArgs(staticStringNotBindable, TestDataBinding.staticStringNotBindable), s);
		Assert.equals("staticStringNotBindablestaticStringNotBindable", s);
		staticStringNotBindable = "new value";
		Assert.equals("staticStringNotBindablestaticStringNotBindable", s);
	}

	public function testBindUnqualifiedMemberMethodNoArgsNotBindableNoFunctionCall():Void {
		var f:() -> String = null;
		// no compiler warning because we're not calling the method
		DataBinding.bind(memberMethodNotBindableNoArgs, f);
		Assert.isTrue(Reflect.compareMethods(this.memberMethodNotBindableNoArgs, f) || this.memberMethodNotBindableNoArgs == f);
	}

	public function testBindQualifiedMemberMethodNoArgsNotBindableNoFunctionCall():Void {
		var f:() -> String = null;
		// no compiler warning because we're not calling the method
		DataBinding.bind(this.memberMethodNotBindableNoArgs, f);
		Assert.isTrue(Reflect.compareMethods(this.memberMethodNotBindableNoArgs, f) || this.memberMethodNotBindableNoArgs == f);
	}

	public function testBindUnqualifiedStaticMethodNoArgsNotBindableNoFunctionCall():Void {
		var f:() -> String = null;
		// no compiler warning because we're not calling the method
		DataBinding.bind(staticMethodNoArgs, f);
		Assert.isTrue(Reflect.compareMethods(TestDataBinding.staticMethodNoArgs, f) || TestDataBinding.staticMethodNoArgs == f);
	}

	public function testBindQualifiedStaticMethodNoArgsNotBindableNoFunctionCall():Void {
		var f:() -> String = null;
		// no compiler warning because we're not calling the method
		DataBinding.bind(TestDataBinding.staticMethodNoArgs, f);
		Assert.isTrue(Reflect.compareMethods(TestDataBinding.staticMethodNoArgs, f) || TestDataBinding.staticMethodNoArgs == f);
	}
}
