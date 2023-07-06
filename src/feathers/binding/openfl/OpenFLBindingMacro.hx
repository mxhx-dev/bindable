package feathers.binding.openfl;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type.ClassType;
#end

class OpenFLBindingMacro {
	public static macro function init():Void {
		DataBinding.setBindingsActivationCallback(activateOpenFLBindings);
		DataBinding.setCreatePropertyWatcherCallback(createWatcher);
	}

	#if macro
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
				$document.addEventListener(openfl.events.Event.ADDED_TO_STAGE, document_addedToStageHandler, false, 0, true);
				$document.addEventListener(openfl.events.Event.REMOVED_FROM_STAGE, document_removedFromStageHandler, false, 0, true);
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
		return macro new feathers.binding.openfl.PropertyWatcher($v{eventName}, () -> $propertyExpr, $destValueListener);
	}
	#end
}
