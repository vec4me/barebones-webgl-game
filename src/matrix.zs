matrix_module := {}
{
	// TODO: Make something which moves declarations as far up as possible with respect to dependency constraints.
	fn matrix_module.link(env) {
		fn make(xx, yx, zx, wx, xy, yy, zy, wy, xz, yz, zz, wz, xw, yw, zw, ww) {
			m4 := {}
			m4.type = "matrix"
			fn m4.copy() {
				return make(xx, yx, zx, wx, xy, yy, zy, wy, xz, yz, zz, wz, xw, yw, zw, ww)
			}
			fn m4.dump() {
				return [
					xx, yx, zx, wx,
					xy, yy, zy, wy,
					xz, yz, zz, wz,
					xw, yw, zw, ww
				]
			}
			fn m4.tdump() {
				return [
					xx, xy, xz, xw,
					yx, yy, yz, yw,
					zx, zy, zz, zw,
					wx, wy, wz, ww
				]
			}
			return m4
		}
		fn matrix_module.pers(n, f, fov) {
			t := tan(0.5*fov)
			return make(
				inner_height/inner_width/t, 0, 0, 0,
				0, 1/t, 0, 0,
				0, 0, (n + f)/(n - f), 2*n*f/(n - f),
				0, 0, -1, 0
			)
		}
		matrix_module.make = make
	}
}
