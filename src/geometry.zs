geometry_module := {}
{
	fn geometry_module.link(env) {
		debug := env.require("debug")
		vector := env.require("vector")
		verts_in := []
		surfs_in := []
		norms_in := []
		let verts = []
		let surfs = []
		let norms = []
		defs := {}
		fn defs["#"]() {}
		fn defs[""]() {}
		fn defs.mtllib() {}
		fn defs.usemtl() {}
		fn defs.o() {}
		fn defs.s() {}
		fn defs.v(vert) {
			verts_in.push([int(vert[0]), int(vert[1]), int(vert[2])])
		}
		fn defs.vt(surf) {
			surfs_in.push([int(surf[0]), int(surf[1])])
		}
		// If you have vertex normals from file, you can enable this
		/*
		fn defs.vn(norm) {
			norms_in.push([int(norm[0]), int(norm[1]), int(norm[2])])
		}
		*/
		// In this example, we compute a flat normal during the face processing.
		fn defs.vn() {}
		fn defs.f(face) {
			let pair_i = 0
			while pair_i < face.length {
				[i, j, k] := face[pair_i].split("/")
				face[pair_i] = [int(i) - 1, int(j) - 1, int(k) - 1]
				++pair_i
			}
			va := face[0][0]
			ta := face[0][1]
			na := face[0][2]
			vb := face[1][0]
			tb := face[1][1]
			nb := face[1][2]
			vc := face[2][0]
			tc := face[2][1]
			nc := face[2][2]
			verts.push(...verts_in[va], ...verts_in[vb], ...verts_in[vc])
			surfs.push(...surfs_in[ta], ...surfs_in[tb], ...surfs_in[tc])
			{
				// Compute flat normal for triangle (first three vertices)
				ax := verts_in[va][0]
				ay := verts_in[va][1]
				az := verts_in[va][2]
				bx := verts_in[vb][0]
				by := verts_in[vb][1]
				bz := verts_in[vb][2]
				cx := verts_in[vc][0]
				cy := verts_in[vc][1]
				cz := verts_in[vc][2]
				// cross product: (B-A) x (C-A)
				let ux = (by - ay) * (cz - az) - (bz - az) * (cy - ay)
				let uy = (bz - az) * (cx - ax) - (bx - ax) * (cz - az)
				let uz = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
				l := sqrt(ux*ux + uy*uy + uz*uz)
				ux /= l
				uy /= l
				uz /= l
				// Assign this normal to all three vertices.
				norms_in[na] = [ux, uy, uz]
				norms_in[nb] = [ux, uy, uz]
				norms_in[nc] = [ux, uy, uz]
			}
			norms.push(...norms_in[na], ...norms_in[nb], ...norms_in[nc])
			if face.length == 4 {
				vd := face[3][0]
				td := face[3][1]
				nd := face[3][2]
				verts.push(...verts_in[vc], ...verts_in[vd], ...verts_in[va])
				surfs.push(...surfs_in[tc], ...surfs_in[td], ...surfs_in[ta])
				{
					ax := verts_in[vc][0]
					ay := verts_in[vc][1]
					az := verts_in[vc][2]
					bx := verts_in[vd][0]
					by := verts_in[vd][1]
					bz := verts_in[vd][2]
					cx := verts_in[va][0]
					cy := verts_in[va][1]
					cz := verts_in[va][2]
					let ux = (by - ay) * (cz - az) - (bz - az) * (cy - ay)
					let uy = (bz - az) * (cx - ax) - (bx - ax) * (cz - az)
					let uz = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
					l := sqrt(ux*ux + uy*uy + uz*uz)
					ux /= l
					uy /= l
					uz /= l
					norms_in[na] = [ux, uy, uz]
					norms_in[nb] = [ux, uy, uz]
					norms_in[nc] = [ux, uy, uz]
				}
				norms.push(...norms_in[nc], ...norms_in[nd], ...norms_in[na])
			}
		}
		fn geometry_module.obj(src) {
			timer := debug.bench("Construct model")
			lines := src.split("\n")
			let i = 0
			while i < lines.length {
				values := lines[i].split(" ")
				defs[values[0]](values.splice(1))
				++i
			}
			timer.end()
			verts = new float32_array(verts)
			surfs = new float32_array(surfs)
			norms = new float32_array(norms)
			fn geometry_module.verts() {
				return verts
			}
			fn geometry_module.surfs() {
				return surfs
			}
			fn geometry_module.norms() {
				return norms
			}
		}
		fn geometry_module.raycast(p, d) {
			// Grab ray origin and direction
			[px, py, pz] := p.dump()
			[dx, dy, dz] := d.dump()
			// Normalize direction (if not already normalized)
			len := math.sqrt(dx * dx + dy * dy + dz * dz)
			if len < 1e-9 {
				// If direction is too small, there's no valid ray
				return false
				// return vector.ident
			}
			ux := dx / len
			uy := dy / len
			uz := dz / len

			let closest_t = infinity
			let hit_point = false
			// To compute the interpolated normal, we need to store:
			let best_u = 0, best_v = 0, best_tri_index = 0

			// For each triangle (3 vertices per triangle = 9 floats)
			for let i = 0; i < verts.length; i += 9 {
				// Triangle vertices: A, B, C
				ax := verts[i + 0]
				ay := verts[i + 1]
				az := verts[i + 2]
				bx := verts[i + 3]
				by := verts[i + 4]
				bz := verts[i + 5]
				cx := verts[i + 6]
				cy := verts[i + 7]
				cz := verts[i + 8]
				// Implement Möller–Trumbore:
				// e1 = B - A
				e1x := bx - ax
				e1y := by - ay
				e1z := bz - az
				// e2 = C - A
				e2x := cx - ax
				e2y := cy - ay
				e2z := cz - az
				// h = D x e2
				hx := uy * e2z - uz * e2y
				hy := uz * e2x - ux * e2z
				hz := ux * e2y - uy * e2x
				// a = e1 . h
				a := e1x * hx + e1y * hy + e1z * hz
				if math.abs(a) < 1e-9 {
					continue // Ray is parallel to this triangle.
				}
				f := 1 / a
				// s = P - A
				sx := px - ax
				sy := py - ay
				sz := pz - az
				// u parameter
				u_val := f * (sx * hx + sy * hy + sz * hz)
				if u_val < 0 || u_val > 1 {
					continue
				}
				// q = s x e1
				qx := sy * e1z - sz * e1y
				qy := sz * e1x - sx * e1z
				qz := sx * e1y - sy * e1x
				// v parameter
				v_val := f * (ux * qx + uy * qy + uz * qz)
				if v_val < 0 || (u_val + v_val) > 1 {
					continue
				}
				// t = f * (e2 . q)
				t := f * (e2x * qx + e2y * qy + e2z * qz)
				if t > 1e-9 && t < closest_t {
					closest_t = t
					best_u = u_val
					best_v = v_val
					best_tri_index = i // Store where this triangle’s data starts.
					// Intersection point
					ix := px + t * ux
					iy := py + t * uy
					iz := pz + t * uz
					hit_point = vector.make(ix, iy, iz, 1)
				}
			}
			// Compute the normal at the hit point (if any intersection was found)
			let hit_normal = false
			if hit_point {
				// Retrieve the vertex normals for the intersected triangle.
				// Since normals array is organized in 9-float groups:
				n_ax := norms[best_tri_index + 0]
				n_ay := norms[best_tri_index + 1]
				n_az := norms[best_tri_index + 2]
				n_bx := norms[best_tri_index + 3]
				n_by := norms[best_tri_index + 4]
				n_bz := norms[best_tri_index + 5]
				n_cx := norms[best_tri_index + 6]
				n_cy := norms[best_tri_index + 7]
				n_cz := norms[best_tri_index + 8]
				// The barycentric coordinate for the third vertex is:
				w := 1 - best_u - best_v
				// Interpolate the normal
				let nx = n_ax * w + n_bx * best_u + n_cx * best_v
				let ny = n_ay * w + n_by * best_u + n_cy * best_v
				let nz = n_az * w + n_bz * best_u + n_cz * best_v
				// Normalize the result
				nl := math.sqrt(nx*nx + ny*ny + nz*nz)
				nx /= nl
				ny /= nl
				nz /= nl
				hit_normal = vector.make(nx, ny, nz, 0)
			}
			hitinfo := {}
			fn hitinfo.p() {
				return hit_point
			}
			fn hitinfo.n() {
				return hit_normal
			}
			return hitinfo
		}

		// Helper: Compute dot product of two 3D vectors.
		fn dot3(ax, ay, az, bx, by, bz) {
			return ax * bx + ay * by + az * bz
		}

		// Helper: Given a point P and triangle vertices A, B, C,
		// returns the closest point on the triangle to P.
		fn closest_point_on_triangle(px, py, pz, ax, ay, az, bx, by, bz, cx, cy, cz) {
			// Compute edge vectors and vector from A to P.
			abx := bx - ax
			aby := by - ay
			abz := bz - az
			acx := cx - ax
			acy := cy - ay
			acz := cz - az
			apx := px - ax
			apy := py - ay
			apz := pz - az

			d1 := dot3(abx, aby, abz, apx, apy, apz)
			d2 := dot3(acx, acy, acz, apx, apy, apz)
			if d1 <= 0 && d2 <= 0 {
				// Closest to vertex A
				return [ ax, ay, az ]
			}

			// Check if P in vertex region outside B.
			bpx := px - bx
			bpy := py - by
			bpz := pz - bz
			d3 := dot3(abx, aby, abz, bpx, bpy, bpz)
			d4 := dot3(acx, acy, acz, bpx, bpy, bpz)
			if d3 >= 0 && d4 <= d3 {
				// Closest to vertex B.
				return [ bx, by, bz ]
			}

			// Check if P in vertex region outside C.
			cpx := px - cx
			cpy := py - cy
			cpz := pz - cz
			d5 := dot3(abx, aby, abz, cpx, cpy, cpz)
			d6 := dot3(acx, acy, acz, cpx, cpy, cpz)
			if d6 >= 0 && d5 <= d6 {
				// Closest to vertex C.
				return [ cx, cy, cz ]
			}

			// Check if P in edge region of AB, and if so return projection onto AB.
			vc := d1 * d4 - d3 * d2
			if vc <= 0 && d1 >= 0 && d3 <= 0 {
				t := d1 / (d1 - d3)
				return [ ax + t * abx, ay + t * aby, az + t * abz ]
			}

			// Check if P in edge region of AC, and if so return projection onto AC.
			vb := d5 * d2 - d1 * d6
			if vb <= 0 && d2 >= 0 && d6 <= 0 {
				t := d2 / (d2 - d6)
				return [ ax + t * acx, ay + t * acy, az + t * acz ]
			}

			// Check if P in edge region of BC, and if so return projection onto BC.
			va := d3 * d6 - d5 * d4
			if va <= 0 && (d4 - d3) >= 0 && (d5 - d6) >= 0 {
				t := (d4 - d3) / ((d4 - d3) + (d5 - d6))
				bcx := cx - bx
				bcy := cy - by
				bcz := cz - bz
				return [ bx + t * bcx, by + t * bcy, bz + t * bcz ]
			}

			// P is inside face region. Compute barycentrics for the projection.
			let denom = 1 / (va + vb + vc)
			v := vb * denom
			w := vc * denom
			u := 1 - v - w
			return [
				u * ax + v * bx + w * cx,
				u * ay + v * by + w * cy,
				u * az + v * bz + w * cz
			]
		}

		// Helper: Given point P and triangle vertices A, B, C,
		// compute barycentric coordinates (u,v,w) for P relative to the triangle.
		fn compute_barycentrics(P, A, B, C) {
			v0x := B[0] - A[0]
			v0y := B[1] - A[1]
			v0z := B[2] - A[2]
			v1x := C[0] - A[0]
			v1y := C[1] - A[1]
			v1z := C[2] - A[2]
			v2x := P[0] - A[0]
			v2y := P[1] - A[1]
			v2z := P[2] - A[2]

			d00 := dot3(v0x, v0y, v0z, v0x, v0y, v0z)
			d01 := dot3(v0x, v0y, v0z, v1x, v1y, v1z)
			d11 := dot3(v1x, v1y, v1z, v1x, v1y, v1z)
			d20 := dot3(v2x, v2y, v2z, v0x, v0y, v0z)
			d21 := dot3(v2x, v2y, v2z, v1x, v1y, v1z)

			denom := d00 * d11 - d01 * d01
			v := (d11 * d20 - d01 * d21) / denom
			w := (d00 * d21 - d01 * d20) / denom
			u := 1 - v - w
			return [ u, v, w ]
		}

		// -------------------------------------------------------------------------
		// geometry_module.project
		// Given an input point (as a vector), finds the closest point on any
		// triangle in the geometry. Also interpolates the normal at that point.
		fn geometry_module.project(p) {
			// Get the coordinates from the vector point.
			[px, py, pz] := p.dump()
			let best_dist_sq = infinity
			let best_proj = nil
			let best_tri_index = nil
			let best_bary = nil

			// Iterate over every triangle (3 vertices per triangle = 9 floats).
			for let i = 0; i < verts.length; i += 9 {
				// Retrieve the three vertices of the triangle.
				ax := verts[i + 0]
				ay := verts[i + 1]
				az := verts[i + 2]
				bx := verts[i + 3]
				by := verts[i + 4]
				bz := verts[i + 5]
				cx := verts[i + 6]
				cy := verts[i + 7]
				cz := verts[i + 8]

				// Find the closest point on this triangle to the input point.
				proj := closest_point_on_triangle(px, py, pz, ax, ay, az, bx, by, bz, cx, cy, cz)
				// Compute squared distance from input point to the projection.
				dx := px - proj[0]
				dy := py - proj[1]
				dz := pz - proj[2]
				dist_sq := dx * dx + dy * dy + dz * dz

				if dist_sq < best_dist_sq {
					best_dist_sq = dist_sq
					best_proj = proj
					best_tri_index = i
					// Also compute barycentrics so that we can interpolate the normal.
					best_bary = compute_barycentrics(proj, { ax, ay, az },
															{ bx, by, bz },
															{ cx, cy, cz })
				}
			}

			// If no projection was computed, return false.
			if !best_proj {
				return false
				// return vector.ident
			}

			// Now interpolate the normal using the barycentrics.
			// The normals array is organized similarly to verts (3 normals per vertex).
			n_ax := norms[best_tri_index + 0],
						n_ay = norms[best_tri_index + 1],
						n_az = norms[best_tri_index + 2]
			n_bx := norms[best_tri_index + 3],
						n_by = norms[best_tri_index + 4],
						n_bz = norms[best_tri_index + 5]
			n_cx := norms[best_tri_index + 6],
						n_cy = norms[best_tri_index + 7],
						n_cz = norms[best_tri_index + 8]

			// Using barycentrics, interpolate.
			u := best_bary.u,
						v = best_bary.v,
						w = best_bary.w
			let nx = n_ax * u + n_bx * v + n_cx * w
			let ny = n_ay * u + n_by * v + n_cy * w
			let nz = n_az * u + n_bz * v + n_cz * w

			// Normalize the interpolated normal.
			let len = math.sqrt(nx * nx + ny * ny + nz * nz)
			if len > 0 {
				nx /= len; ny /= len; nz /= len
			}

			// Create vector points for the projected point and the normal.
			closest_point := vector.make(best_proj[0], best_proj[1], best_proj[2], 1)
			normal_at_point := vector.make(nx, ny, nz, 0)

			// Return an object similar to "raycast"—with functions p() and n()
			// that return the hit point and normal, respectively.
			hitinfo := {}
			fn hitinfo.p() {
				return closest_point
			}
			fn hitinfo.n() {
				return normal_at_point
			}
			return hitinfo
		}

	}
}
