camera_module := {}
{
	fn camera_module.link(env) {
		vector := env.require("vector")
		matrix := env.require("matrix")
		thread := env.require("thread")
		geometry := env.require("geometry")
		trigger := env.require("trigger")
		debug := env.require("debug")
		forward := vector.make(0, 0, -1)

		position := vector.ident.copy()
		rotation := vector.ident.copy()
		let field_of_view = 1.3429
		let velocity = vector.make(0, 0, 0, 0)
		camera_radius := 0.1

		fn linear_accelerate(p, v, v1, a, t) {

		}

		fn camera_module.frus() {
			return matrix.pers(0.1, 10000, field_of_view)
		}
		fn camera_module.p() {
			return position
		}
		fn camera_module.r() {
			return rotation
		}
		fn camera_module.fov() {
			return field_of_view
		}
		fn camera_module.forward() {
			return rotation.copy().qmul(forward)
		}

		fn camera_module.impulse(delta_velocity) {
			velocity.add(delta_velocity)
		}

		fn camera_module.step(dt) {
			let displacement = velocity.copy().scale(dt)
			origin := position.copy()
			length := displacement.length()
			if (length < 1e-9) return

			movement_direction := displacement.copy().norm()
			ray_hit := geometry.raycast(origin, movement_direction)
			if ray_hit {
				distance_to_hit := origin.distance(ray_hit.p())
				if distance_to_hit < length {
					safe_distance := math.max(distance_to_hit - camera_radius, 0)
					displacement.set(movement_direction.copy().scale(safe_distance))
				}
			}
			position.add(displacement)

			projection_hit := geometry.project(position)
			if projection_hit {
				projection_point := projection_hit.p()
				distance_to_surface := position.distance(projection_point)
				if distance_to_surface < camera_radius {
					normal := position.copy().sub(projection_point).norm()
					normal_velocity := velocity.dot(normal)
					if normal_velocity < 0 {
						velocity.project(normal)
					}
				}
			}

			trigger_ray_direction := (velocity.length() > 1e-9) ? velocity.copy().norm() : camera_module.forward()
			trigger.shoot(
				position,
				trigger_ray_direction
			)
		}

		fn camera_module.locate(new_position) {
			position.set(new_position)
			velocity.set(vector.make(0, 0, 0, 0))
		}

		fn camera_module.play_anim() {}

		fn camera_module.make_trigger(position, rotation, size, func) {
			return trigger.make(position, rotation, size, func)
		}
	}
}
