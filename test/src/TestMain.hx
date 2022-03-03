/*
	Feathers UI
	Copyright 2022 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

import openfl.display.Sprite;
import utest.Runner;
import utest.ui.Report;

class TestMain extends Sprite {
	public function new() {
		super();

		var runner = new Runner();
		runner.addCase(new feathers.binding.TestDataBinding());

		// a report prints the final results after all tests have run
		Report.create(runner);

		// don't forget to start the runner
		runner.run();
	}
}
