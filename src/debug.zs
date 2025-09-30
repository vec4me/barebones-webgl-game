debug_module := {}
{
	debug_module.log = console.log
	fn debug_module.link(env) {
		fn debug_module.bench(name) {
			debug := {}
			t0 := performance.now()
			fn debug.end() {
				t1 := performance.now()
				debug_module.log("${name}:", t1 - t0, "ms")
			}
			return debug
		}
	}
}
