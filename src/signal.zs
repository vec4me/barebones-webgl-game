signal_module := {}
{
	fn signal_module.make() {
		signal := {}
		events := []
		fn signal.join(func) {
			conn := {}
			events.push(func)
			fn conn.release() {
				events.splice(events.index_of(func), 1)
			}
			return conn
		}
		fn signal.fire(values) {
			let i = 0
			while i < events.length {
				events[i](values)
				++i
			}
		}
		fn signal.release_all() {
			let i = events.length
			while --i > 0 {
				events[i].release()
			}
		}
		fn signal.remove() {
			signal.join = nil
			signal.fire = nil
			signal.release_all = nil
			signal.remove = nil
			signal = nil
			events = nil
		}
		return signal
	}
}
