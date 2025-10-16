abs := math.abs
acos := math.acos
asin := math.asin
atan2 := math.atan2
cos := math.cos
min := math.min
max := math.max
exp := math.exp
floor := math.floor
log := math.log
pow := math.pow
rand := math.random
sign := math.sign
sin := math.sin
sqrt := math.sqrt
tan := math.tan
int := parse_int
parse_int = nil
hyp := 1.41421356
tau := 6.28318531
pi := 3.1415927
{
	symbols := {}
	env := {}
	fn require(name) {
		if !symbols[name] {
			eval("symbols." + name + "=" + name + "Module")
			if symbols[name].link {
				symbols[name].link(env)
			}
		}
		return symbols[name]
	}
	env.require = require
    env.param = {
        speed: 10,
        volume: 20
    }
	boombox := require("boombox")
	debug := require("debug")
	camera := require("camera")
	graphics := require("graphics")
	input := require("input")
	teller := require("teller")
	thread := require("thread")
	player := require("player")
	geometry := require("geometry")
	vector := require("vector")
	map := require("map")
	let harbinger_dialogue = {
		"a" : {"text": "They always said the stars would guide us, didn’t they? Guide us... home. But they never said what would crawl out when they fell. No, no, no..."},
		"b" : {"text": "Do you hear it? The *hunger*? It’s in the air now, thick as tar. It smells like... like ash and rot, doesn’t it? Sweet, almost. Like it wants you to breathe it in."},
		"c" : {"text":"They called it the end, but that’s such a kind word. This... this isn’t an ending—it’s a gnawing. A devouring. The world doesn’t stop; it’s being *eaten*.",                                                                     },
		"d" : {"text":"Did you see the sun today? Or was it the other one again? The one with too many eyes, blinking, watching? I told them to stop looking up... but they didn’t listen. No one listens anymore.",                                         },
		"e" : {"text":"They want to take it all, you know. Not just the earth, not just the oceans—they want your *thoughts*, your *dreams*. They’ll peel you apart from the inside, thread by thread. The sky... the sky will rip first. You’ll see.",    },
		"f" : {"text":"Or maybe you won’t. Maybe it’ll take you before it gets that far. Lucky, if it does.",                                                                                                                                               },
		"g" : {"text":"Do you know what it feels like to hear the earth scream? It’s not loud. It’s... wet. Like teeth chewing through raw meat.",                                                                                                          },
		"h" : {"text":"You’re still standing here? Hah! Brave, or stupid. But it won’t matter soon. Not for you. Not for anyone. It’s already inside, anyway. It always was."                                                                              }
	}
	map.change.join(fn(name) {
		geometry := map.get_geometry(name)
		geometry.change(geometry)
	})
	graphics.fade()
	player.spawn()
	player.control()
	graphics.fix_canvas()
	// graphics.draw_debug_box(camera.p().copy().add(vector.make(0, 0, -20)), vector.make(0, 0, 0, 1), vector.make(20, 20, 20))
	story0 := camera.make_trigger(camera.p().copy().add(vector.make(0, 0, -20)), vector.make(5, 5, 5), vector.make(0, 0, 0, 1), fn() {
		graphics.fade()
	})

	update := async fn() {

        if(teller.get_initialized_state() && !harbinger_dialogue.b.read) {
           teller.read(harbinger_dialogue.b.text)
           harbinger_dialogue.b.read = true
        }

		[t, dt] := thread.tick()
		direction := input.intent()
		// console.log(direction.dump())
		{
			[rx, ry] := vector.rot_yxz_from_quat(camera.r())
			nearest := vector.ident.copy().qmul(vector.rot_y(ry)).qmul(vector.rot_x(rx))
			camera.r().slerp(nearest, 1 - exp(-8*dt))
		}
		camera.impulse(camera.r().copy().qmul(direction).qmul(camera.r().copy().conj()).scale(500*dt))
		camera.step(dt)
		// console.log(camera.p().dump())
		request_animation_frame(update)
	}
	request_animation_frame(update)
	/*
	network.receive("bullet").join((bullet)
		bullets.push(bullet)
	)
	const b1
	const mp0
	fn onmousedown(info) {
		b1 = true
		mp0 = [info.client_x, info.client_y]
	}
	fn onmouseup(info) {
		b1 = false
		mp1 := [info.client_x, info.client_y]
		while i {
			network.send([
				"bullet",
				mp0,
				[
					0.01*(mp1[0] - mp0[0]) + rand() - 0.5,
					0.01*(mp1[1] - mp0[1]) + rand() - 0.5
				]
			])
			--i
		}
	}
	*/
}
