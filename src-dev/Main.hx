import mxhx.bindable.DataBinding;
import openfl.display.Sprite;

class Main extends Sprite {
	public var src:String = "hello";
	public var dest:String;

	public function new() {
		super();
		trace(dest);
		DataBinding.bind(src, dest, this);
		trace(dest);
	}
}
