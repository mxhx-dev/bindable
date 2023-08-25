import feathers.binding.DataBinding;
import openfl.display.Sprite;

class Main extends Sprite {
	public var src:String = "hello";
	public var dest:String;

	public function new() {
		super();
		DataBinding.bind(src, dest, this);
	}
}
