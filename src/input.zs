input_module := {}
{
	fn input_module.link(env) {
		signal := env.require("signal")
		vector := env.require("vector")
		// require("thread")
		keys_down := {}
		input_module.move = signal.make()
		onkeydown = fn(event) {
			if event.key == "F12" {
				event.prevent_default()
			}
			keys_down[event.code] = true
		}
		onkeyup = fn(event) {
			keys_down[event.code] = false
		}
		onmousemove = fn(event) {
			// thread.tick()
			input_module.move.fire(event)
		}
		oncontextmenu = fn(event) {
			event.prevent_default()
		}
		fn input_module.intent() {
			return vector.make(
				(keys_down["KeyD"] && 1 || 0) - (keys_down["KeyA"] && 1 || 0),
				(keys_down["KeyE"] && 1 || 0) - (keys_down["KeyQ"] && 1 || 0),
				(keys_down["KeyS"] && 1 || 0) - (keys_down["KeyW"] && 1 || 0),
				0
			)
		}
	}
}
