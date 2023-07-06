/*
	feathersui-binding
	Copyright 2023 Bowler Hat LLC. All Rights Reserved.

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
					pending.push(e);
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
			return macro $destination = $source;
		}
		return null;
	}

	private static var bindingsActivationCallback:(Expr, Expr, Expr) -> Expr = defaultBindingsActivationCallback;

	private static function defaultBindingsActivationCallback(document:Expr, activate:Expr, deactivate:Expr):Expr {
		return activate;
	}

	/**
		Allows macros to customize the activation of bindings.
	**/
	public static function setBindingsActivationCallback(callback:(Expr, Expr, Expr) -> Expr):Void {
		bindingsActivationCallback = callback != null ? callback : defaultBindingsActivationCallback;
	}
	#end

	macro public static function bind(source:Expr, destination:Expr, document:Expr = null):Expr {
		var simpleExpr = createSimpleAssignmentExpr(source, destination);
		if (simpleExpr != null) {
			return simpleExpr;
		}

		var callbackExpr = macro function(result:Dynamic):Void {
			$destination = $source;
		}

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
						watchers[$v{i}] = new feathers.binding.openfl.PropertyWatcher($v{eventName}, () -> $expr, $callbackExpr);
					};
				} else {
					createWatcherExpr = macro {
						watchers[$v{i}] = new feathers.binding.openfl.PropertyWatcher($v{eventName}, () -> $expr, $callbackExpr);
						watchers[$v{i - 1}].addChild(watchers[$v{i}]);
					};
				}
				createWatcherExprs.push(createWatcherExpr);
			}
			if (createWatcherExprs.length == 0) {
				// simple assignment
				return macro $destination = $source;
			}
			var createBinding = macro {
				bindings.push({
					var watchers:Array<feathers.binding.IPropertyWatcher> = [];
					$b{createWatcherExprs};
					new feathers.binding.PropertyWatcherBinding(watchers, $watcherParentObject);
				});
			};
			createBindingExprs.push(createBinding);
		}

		var activationCode = bindingsActivationCallback(document, macro activateBindings(), macro deactivateBindings());
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
			$activationCode;
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
