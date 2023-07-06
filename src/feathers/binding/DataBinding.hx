/*
	feathersui-binding
	Copyright 2022 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.binding;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.ClassType;
#end

class DataBinding {
	#if macro
	private static final SIMPLE_ASSIGNMENT_IDENTIFIERS = ["null", "false", "true", "this"];

	private static function createSourceExpr(source:Expr, destination:Expr):Expr {
		var destType = Context.typeof(destination);
		switch (destType) {
			case TInst(t, params):
				var classType = t.get();
				if (classType.name == "String" && classType.pack.length == 0) {
					// special case: if destination type is string, and the
					// source type is not, auto convert the source to a string
					return macro Std.string($source);
				}
			default:
		}
		return macro $source;
	}

	private static function createAssignment(source:Expr, destination:Expr):Expr {
		var sourceExpr = createSourceExpr(source, destination);
		return macro $destination = $sourceExpr;
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

	private static function createSourceItemsInternal(e:Expr, result:Array<DataBindingSourceItem>):Void {
		switch (e.expr) {
			case EField(fieldExpr, fieldName):
				createSourceItemsInternal(fieldExpr, result);
				var item = createSourceItem(e, fieldExpr, fieldName, false);
				result.push(item);
			case EConst(CInt(_) | CFloat(_) | CString(_) | CRegexp(_, _)): // safe to ignore
			case EConst(CIdent(s)):
				var baseExpr:Expr = null;
				var isType = false;
				// local variables have no base expression
				if (!Context.getLocalTVars().exists(s)) {
					var localClass = Context.getLocalClass();
					if (localClass != null) {
						var classType = localClass.get();
						if (Lambda.exists(classType.statics.get(), field -> field.name == s)) {
							baseExpr = macro $i{classType.name};
						} else if (Lambda.exists(classType.fields.get(), field -> field.name == s)) {
							baseExpr = macro this;
						}
					}
					try {
						isType = Context.getType(s) != null;
					} catch (e:Dynamic) {};
				}
				var item = createSourceItem(e, baseExpr, s, baseExpr == null && (isType || s == "this"));
				result.push(item);
			default:
				Context.error('Cannot bind to source: ${ExprTools.toString(e)}', e.pos);
		}
	}

	private static function createSourceItems(source:Expr):Array<DataBindingSourceItem> {
		var result:Array<DataBindingSourceItem> = [];
		createSourceItemsInternal(source, result);
		return result;
	}

	private static function createSourceItem(source:Expr, baseExpr:Expr, fieldName:String, skipWarning:Bool):DataBindingSourceItem {
		var item = new DataBindingSourceItem();
		item.expr = source;
		item.baseExpr = baseExpr;
		item.fieldName = fieldName;
		var isFinal = false;
		if (baseExpr != null) {
			var baseType = Context.typeof(baseExpr);
			var field = getField(baseType, fieldName);
			if (field != null) {
				if (field.isFinal) {
					isFinal = true;
				} else if (field.meta.has(":bindable")) {
					var bindable = field.meta.extract(":bindable")[0];
					switch (bindable.params.length) {
						case 0:
							item.eventName = "propertyChange";
						case 1:
							var param = bindable.params[0];
							switch (param.expr) {
								case EConst(CString(s, kind)):
									item.eventName = s;
								default:
							}
						default:
					}
				}
			}
		}
		if (item.eventName == null && !isFinal && !skipWarning) {
			var posInfos = Context.getPosInfos(source.pos);
			var pos = Context.makePosition({min: posInfos.max - fieldName.length, max: posInfos.max, file: posInfos.file});
			Context.warning('Data binding will not be able to detect assignments to ${fieldName}', pos);
		}
		return item;
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

	private static function collectBaseExprs(source:Expr):Array<Expr> {
		var result:Array<Expr> = [];
		var pending:Array<Expr> = [source];
		while (pending.length > 0) {
			var next = pending.pop();
			switch (next.expr) {
				case EArray(e1, e2):
					pending.push(e1);
					pending.push(e2);
				case EArrayDecl(values):
					for (value in values) {
						pending.push(value);
					}
				case EBinop(op, e1, e2):
					pending.push(e1);
					pending.push(e2);
				case EBlock(exprs):
					for (expr in exprs) {
						pending.push(expr);
					}
				case ECall(e, params):
					for (param in params) {
						pending.push(param);
					}
				case ECast(e, t):
					pending.push(e);
				case ECheckType(e, t):
					pending.push(e);
				case EIf(econd, eif, eelse):
					pending.push(econd);
					pending.push(eif);
					pending.push(eelse);
				#if (haxe_ver >= 4.1)
				case EIs(e, t):
					pending.push(e);
				#end
				case ENew(t, params):
					for (param in params) {
						pending.push(param);
					}
				case EObjectDecl(fields):
					for (field in fields) {
						pending.push(field.expr);
					}
				case EParenthesis(e):
					pending.push(e);
				case ESwitch(e, cases, edef):
					pending.push(e);
					for (c in cases) {
						for (value in c.values) {
							pending.push(value);
						}
					}
				case ETernary(econd, eif, eelse):
					pending.push(econd);
					pending.push(eif);
					pending.push(eelse);
				case EUnop(op, postFix, e):
					pending.push(e);
				default:
					// if the expression doesn't match any of the above,
					// consider it to be a base expression
					result.push(next);
			}
		}
		return result;
	}

	// handle easy cases that need one simple assignment and no events
	private static function createSimpleAssignmentExpr(source:Expr, destination:Expr):Expr {
		var simple = false;
		switch (source.expr) {
			case EConst(CInt(_) | CFloat(_) | CString(_) | CRegexp(_, _)):
				// literals never change values
				simple = true;
			case EConst(CIdent(s)):
				if (SIMPLE_ASSIGNMENT_IDENTIFIERS.indexOf(s) != -1) {
					// certain identifiers will never change values
					simple = true;
				} else {
					if (!Context.getLocalTVars().exists(s)) {
						var baseExpr:Expr = null;
						var localClass = Context.getLocalClass();
						if (localClass != null) {
							var classType = localClass.get();
							if (Lambda.exists(classType.statics.get(), field -> field.name == s && field.isFinal)) {
								// an unqualified final static
								simple = true;
							} else if (Lambda.exists(classType.fields.get(), field -> field.name == s && field.isFinal)) {
								// an unqualified final field
								simple = true;
							}
						}
					}
				}
			case EField(fieldExpr, fieldName):
				switch (fieldExpr.expr) {
					case EConst(CIdent("this")):
						var localClass = Context.getLocalClass();
						if (localClass != null) {
							var classType = localClass.get();
							if (Lambda.exists(classType.fields.get(), field -> field.name == fieldName && field.isFinal)) {
								// a this-qualified final field
								simple = true;
							}
						}
					default:
						var type = Context.typeof(fieldExpr);
						switch (type) {
							case TType(t, params):
								var defType = t.get();
								switch (defType.type) {
									case TAnonymous(a):
										var anonType = a.get();
										if (Lambda.exists(anonType.fields, field -> field.name == fieldName && field.isFinal)) {
											// a class-qualified final static
											simple = true;
										}
									default:
								}
							default:
						}
				}
			default:
		}
		if (simple) {
			return createAssignment(source, destination);
		}
		return null;
	}
	#end

	macro public static function bind(source:Expr, destination:Expr, document:Expr = null):Expr {
		var simpleExpr = createSimpleAssignmentExpr(source, destination);
		if (simpleExpr != null) {
			return simpleExpr;
		}

		var sourceExpr = createSourceExpr(source, destination);
		var callbackExpr = macro(result:Dynamic) -> $destination = $sourceExpr;

		var sourceItemsSets:Array<Array<DataBindingSourceItem>> = [];
		var baseExprs = collectBaseExprs(source);
		for (baseExpr in baseExprs) {
			var sourceItems = createSourceItems(baseExpr);
			sourceItemsSets.push(sourceItems);
		}

		var createBindingExprs:Array<Expr> = [];
		for (sourceItems in sourceItemsSets) {
			var createWatcherExprs:Array<Expr> = [];
			var watcherParentObject:Expr = macro null;
			for (i in 0...sourceItems.length) {
				var item = sourceItems[i];
				var expr = item.expr;
				var baseExpr = item.baseExpr;
				var fieldName = item.fieldName;
				var eventName = item.eventName;
				var createWatcherExpr:Expr = null;
				if (i == 0) {
					watcherParentObject = baseExpr;
					if (watcherParentObject == null) {
						watcherParentObject = expr;
					}
					createWatcherExpr = macro {
						watchers[$v{i}] = new feathers.binding.PropertyWatcher($v{eventName}, () -> $expr, $callbackExpr);
					};
				} else {
					createWatcherExpr = macro {
						watchers[$v{i}] = new feathers.binding.PropertyWatcher($v{eventName}, () -> $expr, $callbackExpr);
						watchers[$v{i - 1}].addChild(watchers[$v{i}]);
					};
				}
				createWatcherExprs.push(createWatcherExpr);
			}
			if (createWatcherExprs.length == 0) {
				return createAssignment(source, destination);
			}
			var createBinding = macro {
				bindings.push({
					var watchers:Array<feathers.binding.PropertyWatcher> = [];
					$b{createWatcherExprs};
					new feathers.binding.PropertyWatcherBinding(watchers, $watcherParentObject);
				});
			};
			createBindingExprs.push(createBinding);
		}

		var hasDocument = checkDocument(document);
		var initCode = if (hasDocument) {
			macro {
				function document_addedToStageHandler(event:openfl.events.Event):Void {
					activateBindings();
				}
				function document_removedFromStageHandler(event:openfl.events.Event):Void {
					deactivateBindings();
				}
				$document.addEventListener(openfl.events.Event.ADDED_TO_STAGE, document_addedToStageHandler, false, 0, true);
				$document.addEventListener(openfl.events.Event.REMOVED_FROM_STAGE, document_removedFromStageHandler, false, 0, true);
				if ($document.stage != null) {
					activateBindings();
				}
			}
		} else {
			macro activateBindings();
		}
		return macro {
			var bindings:Array<feathers.binding.PropertyWatcherBinding> = [];
			$b{createBindingExprs};
			function activateBindings():Void {
				for (binding in bindings) {
					binding.activate();
				}
				$destination = $source;
			}
			function deactivateBindings():Void {
				for (binding in bindings) {
					binding.deactivate();
				}
			}
			$initCode;
		}
	}
}

#if macro
private class DataBindingSourceItem {
	public function new() {}

	public var expr:Expr;
	public var baseExpr:Expr;
	public var fieldName:String;
	public var eventName:String;
}
#end
