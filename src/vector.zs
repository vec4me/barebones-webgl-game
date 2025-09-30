vector_module := {}
{
	fn vector_module.link(env) {
		fn make(x, y, z, w) {
			if !w {
				w = 1
			}
			v4 := {}
			v4.type = "vector"
			fn v4.copy() {
				return make(x, y, z, w)
			}
			fn v4.set(x1, y1, z1, w1) {
				v := x1
				if !v.dump {
					x = x1
					y = y1
					z = z1
					w = w1
				}
				else {
					[x1, y1, z1, w1] = v.dump()
					x = x1
					y = y1
					z = z1
					w = w1
				}
			}
			fn v4.dump() {
				return [x, y, z, w] // i want to dump variable arguments without writing arrays
			}
			fn v4.length() {
				return sqrt(x*x + y*y + z*z + w*w)
			}
			fn v4.dot(b) {
				[bx, by, bz, bw] := b.dump()
				return x*bx + y*by + z*bz + w*bw
			}
			fn v4.conj() {
				x = -x
				y = -y
				z = -z
				return v4
			}
			fn v4.x() {
				return x
			}
			fn v4.y() {
				return y
			}
			fn v4.z() {
				return z
			}
			fn v4.norm() {
				l := sqrt(x*x + y*y + z*z)
				if l > 0 {
					// i want: x, y, z /= l
					x /= l
					y /= l
					z /= l
				}
				return v4
			}
			fn v4.ddump() {
				return [hyp*x, hyp*y, hyp*z, hyp*w]
			}
			fn v4.distance(b) {
				[bx, by, bz, bw] := b.dump()
				dx := bx - x
				dy := by - y
				dz := bz - z
				return sqrt(dx*dx + dy*dy + dz*dz)
			}
			fn v4.cross_imaginary(b) {
				[bx, by, bz, bw] := b.dump()
				return vector_module.make(y*bz - z*by, z*bx - x*bz, x*by - y*bx)
			}
			fn v4.qmul(b) {
				[bx, by, bz, bw] := b.dump()
				x1 := w*bx + x*bw + y*bz - z*by
				y1 := w*by - x*bz + y*bw + z*bx
				z1 := w*bz + x*by - y*bx + z*bw
				w1 := w*bw - x*bx - y*by - z*bz
				x = x1
				y = y1
				z = z1
				w = w1
				return v4
			}
			fn v4.exp(n) {
				l := sqrt(x*x + y*y + z*z)
				if l > 0 {
					t := n*atan2(l, w)
					s := sin(t)/l
					x *= s
					y *= s
					z *= s
					w = cos(t)
				}
				return v4
			}
			fn v4.negate() {
				x = -x
				y = -y
				z = -z
				w = -w
				return v4
			}
			fn v4.project(b) {
				d := v4.dot(b)
				v4.sub(b.copy().scale(d))
				return v4
			}
			fn v4.slerp(b, n) {
				let [ax, ay, az, aw] = v4.dump()
				let [bx, by, bz, bw] = b.dump()
				if ax*bx + ay*by + az*bz + aw*bw < 0 {
					ax = -ax
					ay = -ay
					az = -az
					aw = -aw
				}
				x0 := aw*bx - ax*bw + ay*bz - az*by
				y0 := aw*by - ax*bz - ay*bw + az*bx
				z0 := aw*bz + ax*by - ay*bx - az*bw
				w0 := aw*bw + ax*bx + ay*by + az*bz
				l := sqrt(x0*x0 + y0*y0 + z0*z0)
				if l > 0 {
					t := n*atan2(l, w0)
					s := sin(t)/l
					bx = s*x0
					by = s*y0
					bz = s*z0
					bw = cos(t)
					x = aw*bx + ax*bw - ay*bz + az*by
					y = aw*by + ax*bz + ay*bw - az*bx
					z = aw*bz - ax*by + ay*bx + az*bw
					w = aw*bw - ax*bx - ay*by - az*bz
				}
				return v4
			}
			fn v4.add(b) {
				[bx, by, bz, bw] := b.dump()
				x += bx
				y += by
				z += bz
				w += bw
				return v4
			}
			fn v4.sub(b) {
				[bx, by, bz, bw] := b.dump()
				x -= bx
				y -= by
				z -= bz
				w -= bw
				return v4
			}
			fn v4.scale(r) {
				x *= r
				y *= r
				z *= r
				w *= r
				return v4
			}
			return v4
		}
		fn vector_module.rot_x(t) {
			return make(sin(0.5*t), 0, 0, cos(0.5*t))
		}
		fn vector_module.rot_y(t) {
			return make(0, sin(0.5*t), 0, cos(0.5*t))
		}
		fn vector_module.rot_z(t) {
			return make(0, 0, sin(0.5*t), cos(0.5*t))
		}
		fn vector_module.rot_yxz_from_quat(q) {
			[x, y, z, w] := q.dump()
			rx := asin(2*(w*x - y*z))
			ry := atan2(2*(x*z + w*y), 1 - 2*(x*x + y*y))
			rz := atan2(2*(x*y + w*z), 1 - 2*(x*x + z*z))
			return [rx, ry, rz]
		}
		/*
		fn vector_module.quat_from_rot_yx(q) {
			[x, y, z, w] := q.dump()
			d := w*w + x*x + y*y + z*z
			[xx, yx, zx] := [(w*w + x*x - y*y - z*z)/d, 2*(x*y - w*z)/d, 2*(w*y + x*z)/d]
			[xy, yy, zy] := [2*(x*y + w*z)/d, (w*w - x*x + y*y - z*z)/d, 2*(y*z - w*x)/d]
			[xz, yz, zz] := [2*(x*z - w*y)/d, 2*(w*x + y*z)/d, (w*w - x*x - y*y + z*z)/d]
			kc := xx*xx + xz*xz
			if kc == 0 {
				return [0, atan2(zx, zz), 0]
			}
			return [atan2(xx*yz - xz*yx, xx*zz - xz*zx), atan2(-xz, xx)]
		}
		*/
		fn look(b) {
			[bx, by, bz, bw] := b.dump()
			hyp*(y*bz - z*by)
			hyp*(z*bx - x*bz)
			hyp*(x*by - y*bz)
			hyp
		}
		fn axis_angle(v) {
			[x, y, z] := v.dump()
			l := sqrt(x*x + y*y + z*z)
			s := sin(0.5*l)
			return [s*z/l, s*x/l, s*y/l, cos(0.5*l)]
		}
		fn vector_module.rand() {
			l0 := log(1 - rand())
			l1 := log(1 - rand())
			a0 := tau*rand()
			a1 := tau*rand()
			m0 := sqrt(l0/(l0 + l1))
			m1 := sqrt(l1/(l0 + l1))
			return make(
				m1*sin(a1),
				m0*sin(a0),
				m1*cos(a1),
				m0*cos(a0)
			)
		}
		ident := make(0, 0, 0, 1)
		fn vector_module.from_axis_angle(x, y, z) {
			l := sqrt(x*x + y*y + z*z)
			s := sin(0.5*l)
			if l > 0 {
				return make(s*x/l, s*y/l, s*z/l, cos(0.5*l))
			}
			else {
				return ident
			}
		}
		fn vector_module.tween_linear_velocity(p, v0, v1, s, t) {
			vector := vector_module.make
			d := v1.copy().sub(v0)
			u := d.copy().norm()
			l := d.length() / s
			if t < l {
				position := p.copy()
					.add(v0.copy().scale(t))
					.add(u.copy().scale(0.5 * s * t * t))
				velocity := v0.copy().add(u.copy().scale(s * t))
				return [position, velocity]
			}
			else {
				position := p.copy()
					.add(v0.copy().scale(l))
					.add(u.copy().scale(0.5 * s * l * l))
					.add(v1.copy().scale(t - l))
				velocity := v1.copy()
				return [position, velocity]
			}
		}
		vector_module.ident = ident
		vector_module.make = make
	}
}
