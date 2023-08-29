/*
	Bindable
	Copyright 2023 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package mxhx.bindable;

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
			case null:
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
						} else {
							var field:ClassField = null;
							var currentType = classType;
							while (field == null && currentType != null) {
								field = Lambda.find(currentType.fields.get(), item -> {
									return item.name == s;
								});
								if (currentType.superClass != null) {
									currentType = currentType.superClass.t.get();
								} else {
									currentType = null;
								}
							}
							if (field != null) {
								baseExpr = macro this;
							}
						}
					}
					try {
						isType = Context.getType(s) != null;
					} catch (e:Dynamic) {};
				}
				var item = createSourceItem(e, baseExpr, s, baseExpr == null
					&& (isType || SIMPLE_ASSIGNMENT_IDENTIFIERS.indexOf(s) != -1));
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
		var fieldIsFinal = false;
		var fieldIsMethod = false;
		if (baseExpr != null) {
			var baseExprType = try {
				Context.typeof(baseExpr);
			} catch (e:Dynamic) {
				null;
			}
			var field = getField(baseExprType, fieldName);
			if (field != null) {
				if (field.isFinal) {
					// won't change, no warning required
					fieldIsFinal = true;
				}
				switch (field.kind) {
					case FMethod(k):
						// don't warn for methods, even if they don't have
						// :bindable metadata
						fieldIsMethod = true;
					default:
				}
				item.eventName = getBindableEventName(baseExprType, field);
			}
		}
		if (item.eventName == null && !fieldIsFinal && !fieldIsMethod && !skipWarning) {
			var posInfos = Context.getPosInfos(source.pos);
			var pos = Context.makePosition({min: posInfos.max - fieldName.length, max: posInfos.max, file: posInfos.file});
			Context.warning('Data binding will not be able to detect assignments to ${fieldName}', pos);
		}
		return item;
	}

	private static function getBindableEventName(baseExprType:haxe.macro.Type, field:ClassField):String {
		var classType:ClassType = null;
		switch (baseExprType) {
			case TInst(t, params):
				classType = t.get();
			default:
		}
		if (field.meta.has(":bindable")) {
			var bindable = field.meta.extract(":bindable")[0];
			switch (bindable.params.length) {
				case 0:
					return "propertyChange";
				case 1:
					var param = bindable.params[0];
					switch (param.expr) {
						case EConst(CString(s, kind)):
							return s;
						default:
					}
				default:
			}
		}
		while (classType != null) {
			var qname:String = classType.name;
			if (classType.pack.length > 0) {
				qname = classType.pack.join(".") + "." + qname;
			}
			if (qname != null && customBindableLookup.exists(qname)) {
				var eventLookup = customBindableLookup.get(qname);
				if (eventLookup != null) {
					return eventLookup.get(field.name);
				}
			}
			classType = classType.superClass != null ? classType.superClass.t.get() : null;
		}
		return null;
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
				#if (haxe_ver >= 4.2)
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
							var staticField = Lambda.find(classType.statics.get(), field -> field.name == s);
							if (staticField != null) {
								if (staticField.isFinal) {
									// an unqualified final static
									simple = true;
								} else {
									switch (staticField.kind) {
										case FMethod(MethDynamic):
										case FMethod(k):
											// unqualified static method that won't change at runtime
											simple = true;
										default:
									}
								}
							} else {
								var field:ClassField = null;
								var currentType = classType;
								while (field == null && currentType != null) {
									field = Lambda.find(currentType.fields.get(), item -> item.name == s);
									if (currentType.superClass != null) {
										currentType = currentType.superClass.t.get();
									} else {
										currentType = null;
									}
								}
								if (field != null) {
									if (field.isFinal) {
										// an unqualified final field
										simple = true;
									} else {
										switch (field.kind) {
											case FMethod(MethDynamic):
											case FMethod(k):
												// unqualified method that won't change at runtime
												simple = true;
											default:
										}
									}
								}
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
							var field:ClassField = null;
							var currentType = classType;
							while (field == null && currentType != null) {
								field = Lambda.find(currentType.fields.get(), item -> item.name == fieldName);
								if (currentType.superClass != null) {
									currentType = currentType.superClass.t.get();
								} else {
									currentType = null;
								}
							}
							if (field != null) {
								if (field.isFinal) {
									// a this-qualified final field
									simple = true;
								} else {
									switch (field.kind) {
										case FMethod(MethDynamic):
										case FMethod(k):
											// this-qualified method that won't change at runtime
											simple = true;
										default:
									}
								}
							}
						}
					default:
						var type = try {
							Context.typeof(fieldExpr);
						} catch (e:Dynamic) {
							null;
						}
						switch (type) {
							case TType(t, params):
								var defType = t.get();
								switch (defType.type) {
									case TAnonymous(a):
										var anonType = a.get();
										var field = Lambda.find(anonType.fields, field -> field.name == fieldName);
										if (field != null) {
											if (field.isFinal) {
												// a class-qualified final field
												simple = true;
											} else {
												switch (field.kind) {
													case FMethod(MethDynamic):
													case FMethod(k):
														// class-qualified method that won't change at runtime
														simple = true;
													default:
												}
											}
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

	private static var customBindableLookup:Map<String, Map<String, String>> = [];

	private static var bindingsActivationCallback:(Expr, Expr, Expr) -> Expr = defaultBindingsActivationCallback;

	private static function defaultBindingsActivationCallback(document:Expr, activate:Expr, deactivate:Expr):Expr {
		return activate;
	}

	private static var createWatcherCallback:(String, Expr, Expr) -> Expr = defaultCreateWatcherCallback;

	private static function defaultCreateWatcherCallback(eventName:String, propertyExpr:Expr, destValueListener:Expr):Expr {
		// ignore eventName because unconfigured library doesn't know anything
		// about events.
		// to configure for OpenFL, use OpenFLBindingMacro.init()
		return macro new mxhx.bindable.BasicPropertyWatcher(() -> $propertyExpr, $destValueListener);
	}

	/**
		Allows macros to customize the activation of bindings.

		Note: This macro API is considered unstable and may change in future versions.
	**/
	public static function setBindingsActivationCallback(callback:(Expr, Expr, Expr) -> Expr):Void {
		bindingsActivationCallback = callback != null ? callback : defaultBindingsActivationCallback;
	}

	/**
		Allows macros to customize the creation of IPropertyWatcher objects.

		Note: This macro API is considered unstable and may change in future versions.
	**/
	public static function setCreatePropertyWatcherCallback(callback:(String, Expr, Expr) -> Expr):Void {
		createWatcherCallback = callback != null ? callback : defaultCreateWatcherCallback;
	}

	/**
		Allows macros to add @:bindable metadata that doesn't exist in the source.

		Note: This macro API is considered unstable and may change in future versions.
	**/
	public static function addBindableProperty(qname:String, fieldName:String, eventName:String):Void {
		var eventLookup = customBindableLookup.get(qname);
		if (eventLookup == null) {
			eventLookup = [];
			customBindableLookup.set(qname, eventLookup);
		}
		eventLookup.set(fieldName, eventName);
	}
	#end

	macro public static function bind(source:Expr, destination:Expr, document:Expr = null):Expr {
		var simpleExpr = createSimpleAssignmentExpr(source, destination);
		if (simpleExpr != null) {
			return simpleExpr;
		}

		var destAssignmentExpr = macro try {
			$destination = $source;
		} catch (e:Dynamic) {
			// ignore until no exception is thrown
		}
		var destAssignmentFunc = macro function(result:Dynamic):Void {
			$destAssignmentExpr;
		}

		var sourceItemsSets:Array<Array<DataBindingSourceItem>> = [];
		var baseExprs = collectBaseExprs(source);
		for (baseExpr in baseExprs) {
			var sourceItems = createSourceItems(baseExpr);
			sourceItemsSets.push(sourceItems);
		}

		var createBindingExprs:Array<Expr> = [];
		for (sourceItems in sourceItemsSets) {
			var assignWatcherExprs:Array<Expr> = [];
			var watcherParentObject:Expr = macro null;
			for (i in 0...sourceItems.length) {
				var item = sourceItems[i];
				var expr = item.expr;
				var baseExpr = item.baseExpr;
				var fieldName = item.fieldName;
				var eventName = item.eventName;
				var assignWatcherExpr:Expr = null;
				var createWatcherExpr = createWatcherCallback(eventName, expr, destAssignmentFunc);
				if (i == 0) {
					watcherParentObject = baseExpr;
					if (watcherParentObject == null) {
						watcherParentObject = expr;
					}
					assignWatcherExpr = macro {
						watchers[$v{i}] = $createWatcherExpr;
					};
				} else {
					assignWatcherExpr = macro {
						watchers[$v{i}] = $createWatcherExpr;
						watchers[$v{i - 1}].addChild(watchers[$v{i}]);
					};
				}
				assignWatcherExprs.push(assignWatcherExpr);
			}
			if (assignWatcherExprs.length == 0) {
				// simple assignment
				return macro $destination = $source;
			}
			var createBinding = macro {
				bindings.push({
					var watchers:Array<mxhx.bindable.IPropertyWatcher> = [];
					$b{assignWatcherExprs};
					new mxhx.bindable.PropertyWatcherBinding(watchers, $watcherParentObject);
				});
			};
			createBindingExprs.push(createBinding);
		}

		var activationCode = bindingsActivationCallback(document, macro activateBindings(), macro deactivateBindings());
		return macro {
			var bindings:Array<mxhx.bindable.PropertyWatcherBinding> = [];
			$b{createBindingExprs};
			function activateBindings():Void {
				for (binding in bindings) {
					binding.activate();
				}
				$destAssignmentExpr;
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
