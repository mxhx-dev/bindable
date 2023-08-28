/*
	Bindable
	Copyright 2023 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package mxhx.bindable.openfl;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type.ClassType;
#end

/**
	Configures the library for use with OpenFL. Watches for property changes by
	listening for OpenFL events.

	Add the following to _project.xml_ to configure for OpenFL.

	```xml
	<haxeflag name="--macro mxhx.bindable.openfl.OpenFLBindingMacro.init()"/>
	```
**/
class OpenFLBindingMacro {
	#if macro
	public static function init():Void {
		DataBinding.setBindingsActivationCallback(activateOpenFLBindings);
		DataBinding.setCreatePropertyWatcherCallback(createWatcher);
	}

	private static function activateOpenFLBindings(document:Expr, activate:Expr, deactivate:Expr):Expr {
		var hasDocument = checkDocument(document);
		if (hasDocument) {
			return macro {
				function document_addedToStageHandler(event:openfl.events.Event):Void {
					$activate;
				}
				function document_removedFromStageHandler(event:openfl.events.Event):Void {
					$deactivate;
				}
				$document.addEventListener(openfl.events.Event.ADDED_TO_STAGE, document_addedToStageHandler);
				$document.addEventListener(openfl.events.Event.REMOVED_FROM_STAGE, document_removedFromStageHandler);
				if ($document.stage != null) {
					$activate;
				}
			}
		}
		return activate;
	}

	private static function checkDocument(document:Expr):Bool {
		var hasDocument = document != null;
		if (hasDocument) {
			switch (document.expr) {
				case EConst(CIdent(s)):
					hasDocument = s != "null"; // weird
				default:
			}
		}
		if (hasDocument) {
			var isValidDocument = false;
			var docType = Context.typeof(document);
			switch (docType) {
				case TType(t, params):
					var docTypeType = t.get();
					switch (docTypeType.type) {
						case TInst(t, params):
							var docClassType = t.get();
							if (isDisplayObject(docClassType)) {
								isValidDocument = true;
							}
						default:
					}
				case TInst(t, params):
					var docClassType = t.get();
					if (isDisplayObject(docClassType)) {
						isValidDocument = true;
					}
				default:
			}
			if (!isValidDocument) {
				Context.error('Document must be a subclass of openfl.display.DisplayObject', document.pos);
			}
		}
		return hasDocument;
	}

	private static function isDisplayObject(classType:ClassType):Bool {
		if (classType == null) {
			return false;
		}
		if (classType.name == "DisplayObject") {
			var pack = classType.pack.join(".");
			if (pack == "openfl.display") {
				return true;
			}
			if (pack == "flash.display") {
				return true;
			}
		}
		if (classType.superClass != null) {
			var superClass = classType.superClass.t.get();
			return isDisplayObject(superClass);
		}
		return false;
	}

	private static function createWatcher(eventName:String, propertyExpr:Expr, destValueListener:Expr):Expr {
		return macro new mxhx.bindable.openfl.PropertyWatcher($v{eventName}, () -> $propertyExpr, $destValueListener);
	}
	#end
}
