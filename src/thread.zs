// Maybe this would be better called thread_module or something of that nature.
thread_module := {}
{
	fn thread_module.link(env) {
		let t = 0
		let o = 0
		threads := []
		// queue := []
		fn thread_module.timeout(func, t) {
			return thread_module.make(func, t)
		}
		fn thread_module.interval() {}
		fn thread_module.make(func, t1) {
			thread := {}
			thread.func = func
			thread.t = t1 || t
			fn thread.remove() {
				threads.splice(threads.index_of(thread), 1)
				// queue.splice(queue.index_of(thread), 1)
			}
			fn thread.timeout(delay) {
				thread.t += delay
				threads.sort(fn(a, b) { return a.t - b.t }) // We will do this inneficiently for now.
			}
			threads.push(thread)
			threads.sort(fn(a, b) { return a.t - b.t }) // We will do this inneficiently for now.
			return thread
		}
		// fn thread_module.update(t1) {
		// 	if t < t1 {
		// 		let i = 0
		// 		while i < threads.length {
		// 			thread := threads[i]
		// 			ft := thread.func() || dt
		// 			if !ft {
		// 			}
		// 			else {
		// 				thread.t += ft
		// 				t += ft
		// 			}
		// 			++i
		// 		}
		// 		// Move time from the post-stack events to current time.
		// 	}
		// }
		fn thread_module.update(t1) {
			let i = 0
			while true {
				thread := threads[i]
				if thread {
					if thread.t < t1 {
						thread.func()
						// thread.remove()
					}
					// t0 := thread.t
					// while thread.t < t1 {
					// 	thread.func()
					// 	tafter := thread.t
					// 	if tafter == t0 {
					// 		break
					// 	}
					// }
				}
				else {
					break
				}
				++i
			}
			t = t1
		}
		fn thread_module.now() {
			return t
		}
		fn thread_module.tick() {
			t0 := t
			thread_module.update(0.001*performance.now())
			return [t, t - t0]
		}
	}
}
