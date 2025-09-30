graphics_module := {}
{
	fn graphics_module.link(env) {
		debug := env.require("debug")
		vector := env.require("vector")
		camera := env.require("camera")
		geometry := env.require("geometry")
		thread := env.require("thread")
		camera.link(env)

		canvas := document.create_element("canvas")
		canvas.style.image_rendering = "pixelated"
		fn graphics_module.fix_canvas() {
			canvas.style.position = "fixed"
			canvas.style.top = "0"
		}

		gl := canvas.get_context("webgl2", {
			alpha: false,
			antialias: false,
			desynchronized: true,
			fail_if_major_performance_caveat: false,
			power_preference: "low-power",
			premultiplied_alpha: false,
			preserve_drawing_buffer: true
		})
		if !gl {
			debug.log("failed to initialize context")
		}

		// Helper functions for creating shaders, programs, and buffers.
		fn graphics_module.make_shader(type, src) {
			shader := {}
			id := gl.create_shader(type)
			gl.shader_source(id, src)
			gl.compile_shader(id)
			if !gl.get_shader_parameter(id, gl.COMPILE_STATUS) {
				debug.log(gl.get_shader_info_log(id))
			}
			shader.id = fn() { return id }
			return shader
		}

		fn graphics_module.make_prog(...shaders) {
			prog := {}
			id := gl.create_program()
			for const sh of shaders {
				gl.attach_shader(id, sh.id())
			}
			gl.link_program(id)
			if !gl.get_program_parameter(id, gl.LINK_STATUS) {
				debug.log(gl.get_program_info_log(id))
			}
			prog.use = fn() { return gl.use_program(id) }
			prog.id = fn() { return id }
			fn prog.uniform(name) {
				loc := gl.get_uniform_location(id, name)
				return {
					loc: fn() { return loc },
					send: fn(...values) {
						if values.length == 1 && typeof values[0] == "object" {
							v := values[0]
							if v.type == "vector" {
								gl.uniform4fv(loc, v.dump())
							}
							else if v.type == "matrix" {
								gl.uniform_matrix4fv(loc, false, v.tdump())
							}
							else if v.length == 3 {
								// assume a vec3 array
								gl.uniform3fv(loc, v)
							}
						}
						else if values.length == 1 && typeof values[0] == "number" {
							// single float
							gl.uniform1f(loc, values[0])
						}
						else {
							// multiple floats
							gl.uniform1fv(loc, values)
						}
					}
				}
			}
			fn prog.attr(name) {
				loc := gl.get_attrib_location(id, name)
				gl.enable_vertex_attrib_array(loc)
				return {
					loc: fn() { return loc },
					point: fn(size, type, norm, stride, offset) {
						gl.vertex_attrib_pointer(loc, size, type, norm, stride, offset)
					}
				}
			}
			return prog
		}

		fn graphics_module.make_buff() {
			buff := {}
			id := gl.create_buffer()
			buff.bind = fn(...args) { gl.bind_buffer(...args, id) }
			return buff
		}

		fn graphics_module.fade() {
			t0 := thread.now()
			uhh := thread.make(fn() {
				t := thread.now()
				elapsed := t - t0
				canvas.style.opacity = elapsed
				if elapsed >= 1 {
					canvas.style.opacity = 1
					uhh.remove()
				}
			})
		}

		// ------------------------------
		// SCENE RENDER PROGRAM (pass 1)
		// ------------------------------
		vert_src := `#version 300 es
		flat out int vert_i;
		in vec2 surf;
		in vec3 norm;
		in vec3 vert;
		out vec2 surf_w;
		out vec3 norm_w;
		out vec3 vert_r;
		out vec3 vert_w;
		precision lowp float;
		precision lowp int;
		uniform mat4 frus;
		uniform vec2 viewport_size;
		uniform vec4 cam_p;
		uniform vec4 cam_r;

		vec3 qmul(vec4 q, vec3 p) {
			// quaternion * vector
			vec3 t = 2.0 * cross(q.xyz, p);
			return p + q.w * t + cross(q.xyz, t);
		}

		vec4 conj(vec4 q) {
			return vec4(-q.xyz, q.w);
		}

		void main() {
			vert_w = vert;
			surf_w = surf;
			norm_w = norm;
			vert_r = qmul(conj(cam_r), vert - cam_p.xyz);
			gl_Position = frus * vec4(vert_r, 1.0);
			vert_i = gl_VertexID;
		}
		`

		frag_src := `#version 300 es
		precision lowp float;
		precision lowp int;
		flat in int vert_i;
		in vec2 surf_w;
		in vec3 norm_w;
		in vec3 vert_r;
		in vec3 vert_w;
		out vec4 frag_color;
		uniform vec4 cam_p;
		uniform float time;

		#define DENOISE true
		float hash(vec2 p) {
			// quick-and-dirty 2D hash
			vec3 p3 = fract(vec3(p.xyx) * 0.1031);
			p3 += dot(p3, p3.yzx + 19.19);
			return fract((p3.x + p3.y) * p3.z);
		}

		// Hue-sat-val to RGB
		vec3 rgb_from_hsv(vec3 c) {
			vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
			vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
			return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
		}

		void main() {
			float intensity = 12.0 * inversesqrt(length(vert_r));
			float incidence = dot(norm_w, normalize(cam_p.xyz - vert_w));
			float smoothness = 5.0 * hash(vec2(float(vert_i), 1.0));
			float reflectance = incidence/(incidence*(1.0 - smoothness) + smoothness);
			float luminance = intensity * reflectance;
			float eye = exp(-luminance);

			// Use hue from hash, saturation from 'eye', value = 1 - eye^2
			vec3 color = rgb_from_hsv(vec3(
				hash(vec2(float(vert_i), 12.0)),
				eye,
				1.0 - eye * eye
			));

			// cheap denoise
			if DENOISE {
				color.r += 0.05 * hash(gl_FragCoord.xy + vec2(1.0, 0.0 + time));
				color.g += 0.05 * hash(gl_FragCoord.xy + vec2(0.0, 1.0 + time));
				color.b += 0.05 * hash(gl_FragCoord.xy + vec2(1.0, 1.0 + time));
			}

			// Write geometry with full alpha
			frag_color = vec4(color, 1.0);
		}
		`

		document.document_element.style.background_color = "black"
		document.document_element.style.overflow = "hidden"

		vert_shader := graphics_module.make_shader(gl.VERTEX_SHADER, vert_src)
		frag_shader := graphics_module.make_shader(gl.FRAGMENT_SHADER, frag_src)
		world_prog := graphics_module.make_prog(vert_shader, frag_shader)
		world_prog.use()

		cam_p_u := world_prog.uniform("cam_p")
		cam_r_u := world_prog.uniform("cam_r")
		frus_u := world_prog.uniform("frus")
		time_u := world_prog.uniform("time")

		// Example geometry
		geometry.obj(e1m1_src)
		verts := geometry.verts()

		// Position attribute
		{
			vert_buff := graphics_module.make_buff()
			vert_buff.bind(gl.ARRAY_BUFFER)
			gl.buffer_data(gl.ARRAY_BUFFER, verts, gl.STATIC_DRAW)
			vert_attr := world_prog.attr("vert")
			vert_attr.point(3, gl.FLOAT, false, 0, 0)
		}

		// Normal attribute
		{
			norm_buff := graphics_module.make_buff()
			norm_buff.bind(gl.ARRAY_BUFFER)
			gl.buffer_data(gl.ARRAY_BUFFER, geometry.norms(), gl.STATIC_DRAW)
			norm_attr := world_prog.attr("norm")
			norm_attr.point(3, gl.FLOAT, false, 0, 0)
		}

		// (Optional) Surface attribute
		// {
		//   surf_buff := graphics_module.make_buff()
		//   surf_buff.bind(gl.ARRAY_BUFFER)
		//   gl.buffer_data(gl.ARRAY_BUFFER, geometry.surfs(), gl.STATIC_DRAW)
		//   surf_attr := world_prog.attr("surf")
		//   surf_attr.point(2, gl.FLOAT, false, 0, 0)
		// }

		// We'll store viewport in a uniform if you like, but not strictly necessary
		aspect_u := world_prog.uniform("aspect")
		let aspect

		// Suppose color_tex and depth_buf were created at startup...
		// color_tex := gl.create_texture()
		// depth_buf := gl.create_renderbuffer()
		// fbo := gl.create_framebuffer()

		fn resize() {
			// 1. Resize the canvas HTML element
			canvas.width = inner_width
			canvas.height = inner_height

			// 2. Update the WebGL viewport
			gl.viewport(0, 0, canvas.width, canvas.height)

			// 3. Reallocate the FBO’s color texture to match the new canvas size
			gl.bind_texture(gl.TEXTURE_2D, color_tex)
			gl.tex_image2D(
				gl.TEXTURE_2D,
				0,
				gl.RGBA,
				canvas.width,
				canvas.height,
				0,
				gl.RGBA,
				gl.UNSIGNED_BYTE,
				nil
			)

			// 4. Reallocate the FBO’s depth renderbuffer
			gl.bind_renderbuffer(gl.RENDERBUFFER, depth_buf)
			gl.renderbuffer_storage(
				gl.RENDERBUFFER,
				gl.DEPTH_COMPONENT16,
				canvas.width,
				canvas.height
			)

			// 5. (Optional) Unbind things for cleanliness
			gl.bind_texture(gl.TEXTURE_2D, nil)
			gl.bind_renderbuffer(gl.RENDERBUFFER, nil)

			// 6. Update any uniforms that depend on viewport size/aspect ratio
			frus_u.send(camera.frus())
			aspect = canvas.height / canvas.width
			aspect_u.send(aspect)
		}

		onresize = resize

		fn canvas.onclick() {
			canvas.request_pointer_lock({ unadjusted_movement: true })
		}

		document.document_element.append_child(canvas)

		// -----------------------------------------
		// NEW: Create an offscreen FBO for pass #1
		// -----------------------------------------
		fbo := gl.create_framebuffer()
		gl.bind_framebuffer(gl.FRAMEBUFFER, fbo)

		// Create a color texture w/ alpha
		color_tex := gl.create_texture()
		gl.bind_texture(gl.TEXTURE_2D, color_tex)
		gl.tex_image2D(
			gl.TEXTURE_2D,
			0,
			gl.RGBA,
			canvas.width,
			canvas.height,
			0,
			gl.RGBA,
			gl.UNSIGNED_BYTE,
			nil
		)
		gl.tex_parameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.tex_parameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
		// Attach to FBO
		gl.framebuffer_texture2D(
			gl.FRAMEBUFFER,
			gl.COLOR_ATTACHMENT0,
			gl.TEXTURE_2D,
			color_tex,
			0
		)

		// Create a depth renderbuffer (or depth texture) so depth works
		depth_buf := gl.create_renderbuffer()
		gl.bind_renderbuffer(gl.RENDERBUFFER, depth_buf)
		gl.renderbuffer_storage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, canvas.width, canvas.height)
		gl.framebuffer_renderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, depth_buf)

		if gl.check_framebuffer_status(gl.FRAMEBUFFER) ~= gl.FRAMEBUFFER_COMPLETE {
			debug.log("framebuffer not complete!")
		}
		gl.bind_framebuffer(gl.FRAMEBUFFER, nil)

		// ------------------------------------------
		// NEW: Post-process pass (full-screen quad)
		// ------------------------------------------
		post_vert_src := `#version 300 es
		in vec2 position;
		out vec2 uv;
		void main() {
			uv = 0.5 * (position + vec2(1.0, 1.0)); // from [-1..1] to [0..1]
			gl_Position = vec4(position, 0.0, 1.0);
		}
		`
		post_frag_src := `#version 300 es
		precision lowp float;
		in vec2 uv;
		out vec4 frag_color;
		uniform sampler2D color_tex;
		uniform float time;

		// same hash function
		float hash(vec2 p) {
			vec3 p3 = fract(vec3(p.xyx) * 0.1031);
			p3 += dot(p3, p3.yzx + 19.19);
			return fract((p3.x + p3.y) * p3.z);
		}

		void main() {
			// read color from first pass
			vec4 color = texture(color_tex, uv);

			// If alpha < 0.5, treat as “not drawn,” so we draw static
			if color.a < 0.5 {
				float n = hash(gl_FragCoord.xy + vec2(time));
				color = vec4(vec3(n), 1.0);
			}

			frag_color = color;
		}
		`
		post_vert := graphics_module.make_shader(gl.VERTEX_SHADER, post_vert_src)
		post_frag := graphics_module.make_shader(gl.FRAGMENT_SHADER, post_frag_src)
		post_prog := graphics_module.make_prog(post_vert, post_frag)
		post_pos_loc := post_prog.attr("position")
		post_time_loc := post_prog.uniform("time")
		post_color_tex_loc := post_prog.uniform("color_tex")

		// A simple full-screen quad (-1..1) in XY
		fsq := new float32_array([
			-1, -1,
			 1, -1,
			-1,  1,
			-1,  1,
			 1, -1,
			 1,  1
		])
		fsq_buff := graphics_module.make_buff()
		fsq_buff.bind(gl.ARRAY_BUFFER)
		gl.buffer_data(gl.ARRAY_BUFFER, fsq, gl.STATIC_DRAW)

		// -----------------------------------------------------------
		// NEW: Debug Box drawing
		// -----------------------------------------------------------
		// We'll maintain an array of pending debug box definitions.
		graphics_module.debug_boxes = []
		fn graphics_module.draw_debug_box(p, r, s) {
			// p: vec4 (or an object with x,y,z properties)
			// s: vec3 (scaling in each dimension)
			// r: vec4 (quaternion rotation)
			graphics_module.debug_boxes.push({ p, r, s })
		}

		// Debug box vertex shader and fragment shader.
		// This shader uses the same camera uniforms and quaternion utilities
		// as the world shader.
		debug_vert_src := `#version 300 es
		in vec3 pos;
		uniform vec4 debug_p; // box position (only xyz used)
		uniform vec3 debug_s; // box scale/size
		uniform vec4 debug_r; // box rotation (quaternion)

		uniform mat4 frus;
		uniform vec4 cam_p;
		uniform vec4 cam_r;

		vec3 qmul(vec4 q, vec3 v) {
			vec3 t = 2.0 * cross(q.xyz, v);
			return v + q.w * t + cross(q.xyz, t);
		}
		vec4 conj(vec4 q) { return vec4(-q.xyz, q.w); }

		void main(){
			// pos is in local-space (a unit cube centered at 0)
			// First scale it, then rotate, then translate.
			vec3 world_pos = debug_p.xyz + qmul(debug_r, pos * debug_s);
			// Now, transform the world_pos into camera (view) space.
			vec3 view_pos = qmul(conj(cam_r), world_pos - cam_p.xyz);
			gl_Position = frus * vec4(view_pos, 1.0);
		}
		`
		debug_frag_src := `#version 300 es
		precision lowp float;
		out vec4 frag_color;
		void main(){
			// Draw in red.
			frag_color = vec4(1.0, 0.0, 0.0, 1.0);
		}
		`
		debug_vert_shader := graphics_module.make_shader(gl.VERTEX_SHADER, debug_vert_src)
		debug_frag_shader := graphics_module.make_shader(gl.FRAGMENT_SHADER, debug_frag_src)
		debug_prog := graphics_module.make_prog(debug_vert_shader, debug_frag_shader)
		// Get attribute and uniform locations for the debug shader.
		debug_pos_attr := debug_prog.attr("pos")
		debug_p_u := debug_prog.uniform("debug_p")
		debug_s_u := debug_prog.uniform("debug_s")
		debug_r_u := debug_prog.uniform("debug_r")
		debug_cam_p_u := debug_prog.uniform("cam_p")
		debug_cam_r_u := debug_prog.uniform("cam_r")
		debug_frus_u := debug_prog.uniform("frus")

		// Create a vertex buffer for a solid cube.
		// Instead of a wireframe cube (12 edges), we define 6 faces (12 triangles, 36 vertices).
		cube_faces := new float32_array([
			// Front face (z = 0.5)
			-0.5, -0.5,  0.5,
			 0.5, -0.5,  0.5,
			 0.5,  0.5,  0.5,
			-0.5, -0.5,  0.5,
			 0.5,  0.5,  0.5,
			-0.5,  0.5,  0.5,

			// Back face (z = -0.5)
			-0.5, -0.5, -0.5,
			-0.5,  0.5, -0.5,
			 0.5,  0.5, -0.5,
			-0.5, -0.5, -0.5,
			 0.5,  0.5, -0.5,
			 0.5, -0.5, -0.5,

			// Left face (x = -0.5)
			-0.5, -0.5, -0.5,
			-0.5, -0.5,  0.5,
			-0.5,  0.5,  0.5,
			-0.5, -0.5, -0.5,
			-0.5,  0.5,  0.5,
			-0.5,  0.5, -0.5,

			// Right face (x = 0.5)
			 0.5, -0.5, -0.5,
			 0.5,  0.5, -0.5,
			 0.5,  0.5,  0.5,
			 0.5, -0.5, -0.5,
			 0.5,  0.5,  0.5,
			 0.5, -0.5,  0.5,

			// Top face (y = 0.5)
			-0.5,  0.5, -0.5,
			-0.5,  0.5,  0.5,
			 0.5,  0.5,  0.5,
			-0.5,  0.5, -0.5,
			 0.5,  0.5,  0.5,
			 0.5,  0.5, -0.5,

			// Bottom face (y = -0.5)
			-0.5, -0.5, -0.5,
			 0.5, -0.5, -0.5,
			 0.5, -0.5,  0.5,
			-0.5, -0.5, -0.5,
			 0.5, -0.5,  0.5,
			-0.5, -0.5,  0.5,
		])
		debug_cube_buff := graphics_module.make_buff()
		debug_cube_buff.bind(gl.ARRAY_BUFFER)
		gl.buffer_data(gl.ARRAY_BUFFER, cube_faces, gl.STATIC_DRAW)

		// ------------------------------------------------------
		// Main update loop: Render geometry, then post-process,
		// then draw debug boxes (which overlay everything)
		// ------------------------------------------------------
		thread.make(fn() {
			// PASS #1: Render into offscreen FBO
			gl.bind_framebuffer(gl.FRAMEBUFFER, fbo)
			gl.viewport(0, 0, canvas.width, canvas.height)
			// Clear with alpha=0 so “no geometry = alpha=0”
			gl.clear_color(0, 0, 0, 0)
			gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
			gl.enable(gl.DEPTH_TEST)
			gl.enable(gl.CULL_FACE)
			gl.depth_func(gl.LESS)

			world_prog.use()
			time_u.send(thread.now())
			cam_p_u.send(camera.p())
			cam_r_u.send(camera.r())
			gl.draw_arrays(gl.TRIANGLES, 0, verts.length / 3)

			// PASS #2: Render full-screen quad to default framebuffer
			gl.bind_framebuffer(gl.FRAMEBUFFER, nil)
			gl.viewport(0, 0, canvas.width, canvas.height)
			gl.clear_color(0.0, 0.0, 0.0, 1.0)
			gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

			post_prog.use()
			fsq_buff.bind(gl.ARRAY_BUFFER)
			post_pos_loc.point(2, gl.FLOAT, false, 0, 0)

			// Set uniforms
			post_time_loc.send(thread.now())
			// The texture unit to use for color_tex is texture unit 0
			gl.active_texture(gl.TEXTURE0)
			gl.bind_texture(gl.TEXTURE_2D, color_tex)
			post_color_tex_loc.send(0) // sampler2D takes the texture unit index

			// Draw the fullscreen quad
			gl.draw_arrays(gl.TRIANGLES, 0, 6)

			// ------------------------------------------------------
			// PASS #3: Draw Debug Boxes (always drawn last as red overlays)
			// ------------------------------------------------------
			// Use the debug box program, bind the cube buffer, and
			// set camera uniforms.
			debug_prog.use()
			debug_cube_buff.bind(gl.ARRAY_BUFFER)
			debug_pos_attr.point(3, gl.FLOAT, false, 0, 0)

			debug_cam_p_u.send(camera.p())
			debug_cam_r_u.send(camera.r())
			debug_frus_u.send(camera.frus())

			// Disable depth testing so the debug boxes show up on top.
			gl.disable(gl.DEPTH_TEST)
			// For each pending debug box, set its transform and draw the cube faces.
			for const box of graphics_module.debug_boxes {
				debug_p_u.send(box.p)
				debug_r_u.send(box.r)
				debug_s_u.send(box.s)
				// Draw filled cube faces:
				gl.draw_arrays(gl.TRIANGLES, 0, cube_faces.length / 3)
			}
			// Re-enable depth test if needed later.
			gl.enable(gl.DEPTH_TEST)
			// Clear the debug boxes list.
			// graphics_module.debug_boxes.length = 0
		})

		resize() // call once at startup
	}
}
