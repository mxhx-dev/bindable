/*
	feathersui-binding
	Copyright 2022 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.binding;

import haxe.macro.Type.ClassType;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type.ClassField;
#end

class DataBinding {
	#if macro
	private static final SIMPLE_ASSIGNMENT_IDENTIFIERS = ["null", "false", "true"];

	private static function createAssignment(source:Expr, destination:Expr):Expr {
		var destType = Context.typeof(destination);
		switch (destType) {
			case TInst(t, params):
				var classType = t.get();
				if (classType.name == "String" && classType.pack.length == 0) {
					return macro $destination = Std.string($source);
				}
			default:
		}
		return macro $destination = $source;
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

	private static function getField(type:haxe.macro.Type, fieldName:String):ClassField {
		switch (type) {
			case TInst(t, params):
				var classType = t.get();
				var field:ClassField = null;
				var currentType = classType;
				while (field == null && currentType != null) {
					field = Lambda.find(currentType.fields.get(), item -> {
						return item.name == fieldName;
					});
					if (currentType.superClass != null) {
						currentType = currentType.superClass.t.get();
					} else {
						currentType = null;
					}
				}
				return field;
			case TType(t, params):
				var defType = t.get();
				var defTypeName = defType.name;
				if (StringTools.startsWith(defTypeName, "Class<")) {
					defTypeName = defTypeName.substr(6, defTypeName.length - 7);
					var resolvedType:haxe.macro.Type = null;
					try {
						resolvedType = Context.getType(defTypeName);
					} catch (e:Dynamic) {}
					if (resolvedType != null) {
						switch (resolvedType) {
							case TInst(t, params):
								var classType = t.get();
								var field:ClassField = null;
								if (classType != null) {
									return Lambda.find(classType.statics.get(), item -> {
										return item.name == fieldName;
									});
								}
								return null;
							default:
						}
					}
				}
			default:
		}

		return null;
	}
	#end

	macro public static function bind(source:Expr, destination:Expr, document:Expr = null):Expr {
		// easy cases that need one simple assignment and nothing else
		switch (source.expr) {
			case EConst(CInt(f)):
				return createAssignment(source, destination);
			case EConst(CFloat(f)):
				return createAssignment(source, destination);
			case EConst(CString(s)):
				return createAssignment(source, destination);
			case EConst(CIdent(s)):
				if (SIMPLE_ASSIGNMENT_IDENTIFIERS.indexOf(s) != -1) {
					return createAssignment(source, destination);
				}
			default:
		}

		var sourceBaseExpr:Expr = null;
		var sourceFieldName:String = null;
		switch (source.expr) {
			case EField(e, fieldName):
				sourceBaseExpr = e;
				sourceFieldName = fieldName;
			case EConst(CIdent(s)):
				sourceFieldName = s;
				// local variables have no base expression
				if (!Context.getLocalTVars().exists(s)) {
					var localClass = Context.getLocalClass();
					if (localClass != null) {
						var classType = localClass.get();
						if (Lambda.exists(classType.statics.get(), field -> field.name == sourceFieldName)) {
							sourceBaseExpr = macro $i{classType.name};
						} else if (Lambda.exists(classType.fields.get(), field -> field.name == sourceFieldName)) {
							sourceBaseExpr = macro this;
						}
					}
				}
			default:
		}

		if (sourceFieldName == null) {
			Context.error('Cannot bind to source: ${ExprTools.toString(source)}', source.pos);
		}
		var sourceIsFinal = false;
		var sourceEventName:String = null;
		if (sourceBaseExpr != null) {
			var baseType = Context.typeof(sourceBaseExpr);
			var field = getField(baseType, sourceFieldName);
			if (field != null) {
				if (field.isFinal) {
					sourceIsFinal = true;
				} else if (field.meta.has(":bindable")) {
					var bindable = field.meta.extract(":bindable")[0];
					switch (bindable.params.length) {
						case 0:
							sourceEventName = "propertyChange";
						case 1:
							var param = bindable.params[0];
							switch (param.expr) {
								case EConst(CString(s, kind)):
									sourceEventName = s;
								default:
							}
						default:
					}
				}
			}
		}
		var addListener:Expr = macro {};
		var removeListener:Expr = macro {};
		if (sourceEventName != null) {
			addListener = macro $sourceBaseExpr.addEventListener($v{sourceEventName}, bindingHandler, false, 100, true);
			removeListener = macro $sourceBaseExpr.removeEventListener($v{sourceEventName}, bindingHandler);
		} else if (!sourceIsFinal) {
			Context.warning('Data binding will not be able to detect assignments to $sourceFieldName', source.pos);
		}
		var assignment = createAssignment(source, destination);

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
		var initCode = macro {
			activateBinding();
		};
		if (hasDocument) {
			initCode = macro {
				function document_addedToStageHandler(event:openfl.events.Event):Void {
					activateBinding();
				}
				function document_removedFromStageHandler(event:openfl.events.Event):Void {
					deactivateBinding();
				}
				$document.addEventListener(openfl.events.Event.ADDED_TO_STAGE, document_addedToStageHandler, false, 0, true);
				$document.addEventListener(openfl.events.Event.REMOVED_FROM_STAGE, document_removedFromStageHandler, false, 0, true);
				if ($document.stage != null) {
					activateBinding();
				}
			}
		}

		return macro {
			(function():Void {
				var active = false;
				function executeBinding():Void {
					try {
						$assignment;
					} catch (e:Dynamic) {}
				}
				function bindingHandler(event:openfl.events.Event):Void {
					executeBinding();
				}
				function deactivateBinding():Void {
					if (!active) {
						return;
					}
					$removeListener;
					active = false;
				}
				function activateBinding():Void {
					if (active) {
						return;
					}
					$addListener;
					active = true;
					executeBinding();
				}
				$initCode;
			})();
		};
	}
}
