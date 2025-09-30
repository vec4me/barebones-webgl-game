trigger_module := {}
{
	fn trigger_module.link(env) {
		graphics := env.require("graphics")
		// Storage for triggers.
		triggers := []
		// Create a trigger with a position, size, orientation (optional), and an activation function.
		//
		// Parameters:
		//   p: Position vector representing the trigger’s center (e.g. {x: 0, y: 0, z: 0}).
		//   s: Size object containing width, height, and depth (e.g. {width: 10, height: 5, depth: 3}).
		//   func: The function to call when the trigger is activated.
		//   quat (optional): The orientation of the trigger represented by a unit quaternion
		//                    (default is no rotation: {x:0, y:0, z:0, w:1}).
		//
		// In this design, the trigger’s “local box” is axis-aligned with the center at (0,0,0)
		// and extents of half of the provided size.
		fn trigger_module.make(p, r, s, func) {
			trigger_obj := {
				// Store the center position.
				x: p.x(),
				y: p.y(),
				z: p.z(),
				// The full size is stored; the local box runs from -width/2 to width/2, etc.
				w: s.width,
				h: s.height,
				d: s.depth,
				// Orientation stored as a quaternion.
				r: r,
				// Activation function.
				func: func,
				// Provide a remove method.
				remove: fn() {
					idx := triggers.index_of(trigger_obj)
					if idx ~= -1 {
						triggers.splice(idx, 1)
					}
				}
			}
			triggers.push(trigger_obj)
			// graphics.draw_debug_box(p, s, r)
			return trigger_obj
		}
		// Ray-box intersection for oriented boxes.
		// The function expects:
		//   p: The ray origin (world coordinates)
		//   d: The ray direction (world coordinates)
		//
		// For each trigger we bring the ray into the trigger’s local space where the box is axis-aligned,
		// then we use the standard slab method.
		fn trigger_module.shoot(p, d) {
			for let i = 0, len = triggers.length; i < len; i++ {
				t := triggers[i]
				// Step 1. Transform the ray into the trigger's local space.
				// Compute the ray’s origin relative to the trigger’s center.
				rel_origin := {
					x: p.x - t.x,
					y: p.y - t.y,
					z: p.z - t.z
				}
				// To “undo” the trigger’s rotation, we rotate the ray by the inverse rotation.
				// For unit quaternions, the inverse is the conjugate.
				// Extract the quaternion components using .dump(), which returns [x, y, z, w]
				[qx, qy, qz, qw] := t.r.dump()
				// The conjugate/inverse is then:
				iqx := -qx
				iqy := -qy
				iqz := -qz
				iqw := qw
				// --- Helper inline function (expanded inline) ---
				// Instead of using external class functions, we manually rotate a vector v (an object {x,y,z})
				// by the quaternion given by (iqx, iqy, iqz, iqw):
				//   t = 2*(iq_vector × v)
				//   v' = v + iqw*t + (iq_vector × t)
				//
				// We'll do this once for rel_origin and again for the ray direction d.
				// Rotation for a generic vector v:
				// (We inline the math; in production code you might extract this to a helper.)
				fn rotate_by_inv_quat(v) {
					vx := v.x
					vy := v.y
					vz := v.z
					// Compute cross product: iq_vector × v:
					cross1_x := iqy * vz - iqz * vy
					cross1_y := iqz * vx - iqx * vz
					cross1_z := iqx * vy - iqy * vx
					// Multiply by 2:
					tx := 2 * cross1_x
					ty := 2 * cross1_y
					tz := 2 * cross1_z
					// Compute second cross product: iq_vector × t:
					cross2_x := iqy * tz - iqz * ty
					cross2_y := iqz * tx - iqx * tz
					cross2_z := iqx * ty - iqy * tx
					return {
						x: vx + iqw * tx + cross2_x,
						y: vy + iqw * ty + cross2_y,
						z: vz + iqw * tz + cross2_z
					}
				}
				// Rotate the relative origin and the ray direction.
				local_origin := rotate_by_inv_quat(rel_origin)
				local_dir    := rotate_by_inv_quat(d)
				// Step 2. Define the AABB bounds in local space.
				// The box is centered at (0,0,0) and extends half-size in every direction.
				half_w := t.w / 2
				half_h := t.h / 2
				half_d := t.d / 2
				xmin := -half_w
				xmax := half_w
				ymin := -half_h
				ymax := half_h
				zmin := -half_d
				zmax := half_d
				// Step 3. Compute intersections with each slab.
				// Precompute inverse components of the ray direction.
				invx := 1 / local_dir.x,
							invy = 1 / local_dir.y,
							invz = 1 / local_dir.z
				// X slab.
				let tx1 = (xmin - local_origin.x) * invx,
						tx2 = (xmax - local_origin.x) * invx
				let tminx = math.min(tx1, tx2),
						tmaxx = math.max(tx1, tx2)
				// Y slab.
				let ty1 = (ymin - local_origin.y) * invy,
						ty2 = (ymax - local_origin.y) * invy
				let tminy = math.min(ty1, ty2),
						tmaxy = math.max(ty1, ty2)
				// Z slab.
				let tz1 = (zmin - local_origin.z) * invz,
						tz2 = (zmax - local_origin.z) * invz
				let tminz = math.min(tz1, tz2),
						tmaxz = math.max(tz1, tz2)
				// Determine the overall intersection intervals.
				tmin := math.max(tminx, tminy, tminz)
				tmax := math.min(tmaxx, tmaxy, tmaxz)
				// Step 4. If there is an intersection in front of the ray, activate the trigger.
				if tmax >= (tmin < 0 ? 0 : tmin) {
					t.func()
				}
			}
		}
	}
}
