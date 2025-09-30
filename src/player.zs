player_module := {}
{
	fn player_module.link(env) {
		map := env.require("map")
		camera := env.require("camera")
		vector := env.require("vector")
		input := env.require("input")
		fn player_module.spawn() {
			start_points := map.start_points()
			camera.locate(start_points[0])
		}
		let control_stuff
		fn player_module.control() {
			control_stuff = input.move.join(fn(event) {
				camera.r().qmul(vector.from_axis_angle(-2/inner_height*event.movement_y, -2/inner_height*event.movement_x, 0))
			})
		}
		fn player_module.release() {
			input.move.release_all()
			control_stuff.release()
		}
		fn player_module.update(dt) {
			apply_input()
			a.add(g.copy().scale(dt))
			v.add(a.copy().scale(dt))
			horizontal_velocity := vector.make(v.x(), v.y(), 0)
			if horizontal_velocity.length() > MAX_SPEED {
				horizontal_velocity.norm().scale(MAX_SPEED)
				v.set(horizontal_velocity.x(), horizontal_velocity.y(), v.z())
			}
			a.set(0, 0, 0)
			dp := v.copy().scale(dt)
			origin := p.copy()
			length := dp.length()
			if length > 1e-9 {
				dir := dp.copy().norm()
				hit := geometry.raycast(origin, dir, length, "feet")
				if hit {
					dist_to_hit := origin.distance(hit.p())
					if dist_to_hit < length {
						safe_dist := math.max(dist_to_hit - 0.1, 0)
						dp.set(dir.copy().scale(safe_dist))
						normal := hit.n()
						if normal {
							v.project(normal)
						}
					}
				}
			}
			p.add(dp)
			v.scale(DAMPING)
			camera.locate(p.copy().add(vector.make(0, 0, 30)))
		}
	}
}
