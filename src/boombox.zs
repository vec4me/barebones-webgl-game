boombox_module := {}
{
	fn boombox_module.link(env) {
		fn freq_from_note(note) {
			note_map := {
				"C": 261.63,
				"C#": 277.18,
				"D": 293.66,
				"D#": 311.13,
				"E": 329.63,
				"F": 349.23,
				"F#": 369.99,
				"G": 392.00,
				"G#": 415.30,
				"A": 440.00,
				"A#": 466.16,
				"B": 493.88
			}
			octave := int(note[note.length - 1])
			note_string := note.slice(0, -1)
			return note_map[note_string]*pow(2, octave - 4)
		}
		fn play_at_pitch(url, pitch) {
			src := new audio(url)
			src.playback_rate = pitch
			src.preserves_pitch = false
			src.volume = 0.2 // Volume is proportional to 1.
			//src.loop = true
			src.play()
		}
		meat := "data:image/jpg;base64,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"
		idk := "data:audio/mpeg;base64,SUQzBAAAAAAAI1RTU0UAAAAPAAADTGF2ZjU4Ljc2LjEwMAAAAAAAAAAAAAAA/+MYZAADUD04AKEMAALwBmwBQAAA/5G/UjT0IRQAQwn/L4nPg/UcEgY/l3/hgoGP/l38Hy7/5R3Of4fV9RRmUEb5UYXdTikm/+MYZAwDyJGGAMKIAAXhLwQBghAAOKgocyCfncnKKO2g/+r5Ow9qft0+s5xrGHc+Yimh1G/elFan/3Gw/jYR0DLS7suUsq2L/+MYZAkD7ImAAOOUAASJEwABwhAAnHE2VKDHhASQ0T/28TI+owW/1CHW/V+//w7YjPUF5+n6fBv52/4c7qVi8MEJqC9geq0f/+MYZAoDvImCZAiiNgTI5vgACA4gEbYP4SbGv+3hP0DL/w/nux31fyfeXKV59Tsa+RPyj/QzxQ/iH5zoxML3i2ujPRXKPQS2/+MYZAwELJmAAKOIAAMAzwABQgAAQ+okc8Iy2r/VuYNC76W/1BJ+Cf/9H7f/bn1yeL6P+3gtakCZpgPn+7ONDh5H84VqGDSh/+MYZBEEbImCAMOUAAYorvwBhRAAca+tWCvmX8Y2I4/oLSX//8v9Ss3/YpxRjI/uH1BBVnDvvsgxc7rl75X/6IGZKCwkQ2K7/+MYZAgB8AcSAOGAAISgAhgBwgAA5eivyeCsHb/4ieCoCDgNAUFSyoKjDwNLDRZMQU1FMy4xMDCqqqqqqqqqqqqqqqqqqqqq"
		easy_does_it := "data:audio/mpeg;base64,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"
		channels := 1
		dur := 0.4
		ctx := new audio_context()
		//sample_rate := ctx.sample_rate
		sample_rate := 8000
		total_samples := dur*sample_rate
		fn boombox_module.make() {
			boombox := {}
			fn boombox.step(dt) {
			}
			fn boombox.play_note(note) {
				freq := freq_from_note(note)
				buff := ctx.make_buffer(channels, total_samples, sample_rate)
				channel_data := buff.get_channelData(0)
				if rand() > 0.7 {
					let i = 0
					while i < total_samples {
						t := i/sample_rate
						channel_data[i] = 0.1*sin(2*pi*freq*(t + 0.0005*sin(80*t)))*exp(-10*t)
						++i
					}
				}
				else {
					let i = 0
					while i < total_samples {
						t := i/sample_rate
						channel_data[i] = 0.1*(2*pi*freq*t%1)*exp(-10*t)
						++i
					}
					/*
					let i = 0
					while i < total_samples {
						t := i/sample_rate
						channel_data[i] = 0.1*(2*pi*freq*(t + 0.0005*sin(80*t))%1)*exp(-10*t)
						++i
					}
					*/
				}
				src := ctx.make_bufferSource()
				src.buff = buff
				src.connect(ctx.destination)
				src.start()
				//play_at_pitch(idk, 1/440*freq)
				//play_at_pitch(easy_does_it, 1/440*freq)
			}
			// thread.interval(fn() {
			let i = 0
			// 	while i < floor(5*rand()) {
			// 		boombox.play_note(["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"][floor(12*rand())] + (2 + floor(4*rand())))
			// 	}
			// }, 500)
			// thread.interval(fn() {
			// 	play_at_pitch(drum, 1/440*freq_from_note(note + offset))
			// }, 200)
			return boombox
		}
		{
			fn rand_chord_progression(chords_count) {
				root_notes := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
				chord_types := ["major", "minor", "diminished", "augmented", "sus2", "sus4"]
				progression := []
				let i = 0
				while i < chords_count {
					rand_root := root_notes[floor(rand()*root_notes.length)]
					rand_chord_type := chord_types[floor(rand()*chord_types.length)]
					chord := rand_root + " " + rand_chord_type
					notes := gchord(rand_root, rand_chord_type)
					progression.push(...notes)
					++i
				}
				return progression
			}
			// fn gchord(root, chord_type) {
			// 	notes := []
			// 	switch(chord_type) {
			// 		case "major":
			// 			notes.push(root + "4", root + "3", root + "2")
			// 			break
			// 		case "minor":
			// 			notes.push(root + "4", root + "3", root + "1")
			// 			break
			// 		case "diminished":
			// 			notes.push(root + "4", root + "b3", root + "b2")
			// 			break
			// 		case "augmented":
			// 			notes.push(root + "4", root + "3", root + "#2")
			// 			break
			// 		case "sus2":
			// 			notes.push(root + "4", root + "2", root + "1")
			// 			break
			// 		case "sus4":
			// 			notes.push(root + "4", root + "b3", root + "2")
			// 			break
			// 		default:
			// 			break
			// 	}
			// 	return notes
			// }
			// example usage
			// progression := rand_chord_progression(4) // generate a progression of 4 chords
		}
		// let chord
		// {
		// 	semitone_map := {
		// 		"C": 0, "C#": 1, "Db": 1,
		// 		"D": 2, "D#": 3, "Eb": 3,
		// 		"E": 4, "Fb": 4, "E#": 5,
		// 		"F": 5, "F#": 6, "Gb": 6,
		// 		"G": 7, "G#": 8, "Ab": 8,
		// 		"A": 9, "A#":10, "Bb":10,
		// 		"B":11, "Cb":11, "B#": 0
		// 	}
		// 	note_names_sharp := [
		// 		"C", "C#", "D", "D#", "E", "F",
		// 		"F#", "G", "G#", "A", "A#", "B"
		// 	]
		// 	base_chords := {
		// 		"M": [0, 4, 7],
		// 		"": [0, 4, 7],
		// 		"m": [0, 3, 7],
		// 		"7": [0, 4, 7, 10],
		// 		"maj7": [0, 4, 7, 11],
		// 		"m7": [0, 3, 7, 10],
		// 		"dim": [0, 3, 6],
		// 		"dim7": [0, 3, 6, 9],
		// 	}
		// 	extensions := {
		// 		"9": 2, // major 9th = 2 semitones above an octave
		// 		"b9": 1,
		// 		"#9": 3,
		// 		"11": 5,
		// 		"#11": 6,
		// 		"b5": 6,
		// 		"#5": 8,
		// 		"13": 9,
		// 		"b13": 8,
		// 	}
		// 	fn chord(chord) {
		// 		root_match := chord.match(/^([A-G](#|b)?)/i)
		// 		if !root_match {
		// 			return // unrecognized root
		// 		}
		// 		root := root_match[0]
		// 		let remainder = chord.slice(root.length)
		// 		let base_chord = ""
		// 		known_base_chords := Object.keys(base_chords).sort(fn(a, b) { return b.length - a.length })
		// 		while i < known_base_chords.length {
		// 			if remainder.starts_with(type) {
		// 				base_chord = type
		// 				remainder = remainder.slice(type.length)
		// 				break
		// 			}
		// 		}
		// 		extensions := []
		// 		while remainder.length > 0 {
		// 			let matched_extension = nil
		// 			while i < Object.keys(extensions).sort(fn(a, b) { return b.length - a.length }).length {
		// 				if remainder.starts_with(ext_key) {
		// 					matched_extension = ext_key
		// 					extensions.push(matchedExtension)
		// 					remainder = remainder.slice(ext_key.length) // remove that chunk
		// 					break
		// 				}
		// 			}
		// 			if !matchedExtension {
		// 				break
		// 			}
		// 		}
		// 		debug.log(chord, "->", root, base_chord, extensions)
		// 		return { root, base_chord, extensions }
		// 	}
		// }
		let gchord
		{
			// 1) Map note names to semitone offsets (0 = C, 1 = C#/Db, ..., 11 = B).
			NOTE_OFFSETS := {
				"C": 0,
				"C#": 1, "Db": 1,
				"D": 2,
				"D#": 3, "Eb": 3,
				"E": 4,
				"F": 5,
				"F#": 6, "Gb": 6,
				"G": 7,
				"G#": 8, "Ab": 8,
				"A": 9,
				"A#": 10, "Bb": 10,
				"B": 11
			}
			// 2) Basic chord-type intervals (triads, etc.).
			// Each entry is an array of intervals ABOVE the root in semitones.
			BASE_CHORDS := {
				// If there"s no “type” (like plain "C"), let"s assume a major triad
				"": [0, 4, 7],
				"m": [0, 3, 7],
				"dim": [0, 3, 6],
				"aug": [0, 4, 8],
				"5": [0, 7],
				// e.g. “sus2”, “sus4”, etc. can go here
			}
			// 3) Possible extensions to add on top of the base chord
			// (these are also intervals *above the root*).
			// You can expand these with #9, b9, #11, etc.
			EXTENSIONS_MAP := {
				"7": [10], // minor 7th
				"maj7": [11], // major 7th
				"9": [14], // 2 octaves + a major 2nd
				"11": [17],
				"13": [21]
			}
			gchord = fn(chord) {
				root_match := chord.match(/^([A-G](#|b)?)/i)
				if !root_match {
					return []
				}
				root_string := root_match[0]
				let remainder = chord.slice(root_string.length)
				let base_chord_type = ""
				known_chord_types := Object.keys(BASE_CHORDS).sort(fn(a, b) { return b.length - a.length })
				let i = 0
				while i < knownChordTypes.length {
					type := knownChordTypes[i]
					if remainder.starts_with(type) {
						base_chord_type = type
						remainder = remainder.slice(type.length)
						break
					}
					++i
				}
				parsed_extensions := []
				known_extensions := Object.keys(EXTENSIONS_MAP).sort(fn(a, b) { return b.length - a.length })
				while remainder.length > 0 {
					let matched_extension = nil
					while i < knownExtensions.length {
						if remainder.starts_with(extKey) {
							matched_extension = extKey
							parsed_extensions.push(matchedExtension)
							remainder = remainder.slice(extKey.length)
							break
						}
					}
					if !matchedExtension {
						break
					}
				}
				// Debugging
				// debug.log(
				// 	'chord: "${chord}" -> root: "${root_string}", type: "${base_chord_type}", exts: [${parsed_extensions}]'
				// )
				// --- 4) Convert root to offset (0-11). If not found, just exit -----------
				root_offset := NOTE_OFFSETS[root_string.to_upper_case()]
				if !typeof root_offset {
					return []
				}
				// --- 5) Collect all intervals from base chord + extensions ---------------
				// e.g. for "Cmaj7", base chord intervals = [0,4,7], extension = [11].
				let chord_intervals = BASE_CHORDS[base_chord_type] || []
				let extension_intervals = []
				parsed_extensions.for_each(fn(ext) {
					if EXTENSIONS_MAP[ext] {
						extension_intervals.push(...EXTENSIONS_MAP[ext])
					}
				})
				// Combine them into one array (avoiding duplicates)
				let all_intervals = [...chord_intervals]
				extension_intervals.for_each(fn(iv) {
					if !all_intervals.includes(iv) {
						all_intervals.push(iv)
					}
				})
				// Sort them ascending so the chord tones are in ascending order
				all_intervals.sort(fn(a, b) { return a - b })
				// --- 6) Decide on a "base MIDI note" or "base offset" for the chord -------
				// For example, let"s pick 48 (C3) so that if the chord root is "C",
				// the root note becomes 48. But if we want "B" to be 47,
				// we can choose 47 for the "B" root, etc.
				//
				// *If you specifically want the root for "B" to be 47, you could do a
				// dynamic approach: base_midi = 48 - NOTE_OFFSETS["C"] + (some offset).
				// But let"s keep it simple with a single base for all.
				BASE_MIDI := 48 // If "C" is 48, "C#" is 49, etc.
				// Map intervals => actual note numbers
				notes := all_intervals.map(fn(interval) {
					// root_offset + interval is how many semitones above "C"
					return BASE_MIDI + root_offset + interval
				})
				// Return the array, e.g. [48, 52, 55] for a C major triad
				return notes
			}
			// ---------------------------------------------------------------------------
			// Some quick tests:
			// debug.log(gchord("C")) // => [48, 52, 55] (C3, E3, G3)
			// debug.log(gchord("C7")) // => [48, 52, 55, 58]
			// debug.log(gchord("Cm7")) // => [48, 51, 55, 58]
			// debug.log(gchord("F#m9")) // => e.g. [54, 57, 61, 66, 68]
			// debug.log(gchord("Bbmaj7")) // => [58, 62, 65, 69]
		}
		soft_middle := "data:audio/mpeg;base64,SUQzBAAAAAADNVRJVDIAAAAgAAADQyA0NDAgVHVuaW5nIE5vdGUgKDEwIG1pbnV0ZXMpAFRYWFgAAAAyAAADUFVSTABodHRwczovL3d3dy55b3V0dWJlLmNvbS93YXRjaD92PTVPWmFjMFkxTGFzAFRYWFgAAAA1AAADQ09NTUVOVABodHRwczovL3d3dy55b3V0dWJlLmNvbS93YXRjaD92PTVPWmFjMFkxTGFzAFRYWFgAAAAgAAADQ09NUEFUSUJMRV9CUkFORFMAaXNvNmF2YzFtcDQxAFRYWFgAAAASAAADTUFKT1JfQlJBTkQAZGFzaABUWFhYAAAAEQAAA01JTk9SX1ZFUlNJT04AMABUUEUxAAAAEwAAA1RoZSBXaXNlIE11c2ljaWFuAFREUkMAAAAKAAADMjAyMTExMjYAVFhYWAAAACUAAANERVNDUklQVElPTgBDIDQ0MGh6IGRyb25lIHRvbmUgKEM0KQBUWFhYAAAAIgAAA1NZTk9QU0lTAEMgNDQwaHogZHJvbmUgdG9uZSAoQzQpAFRTU0UAAAAPAAADTGF2ZjU4Ljc2LjEwMAAAAAAAAAAAAAAA/+MYZAADPAB4BKAAAAOQANhJQAAAh//wws///4neHyjg+XPlDk5+Jz4PwQcUcD4MQ////+o4UcJ33//7yir///TcJwj/0//8/+MYZAoEdNNeAMa0AAPoBgABgBAAwJRt///EYHhQaE4GP///jBnlzMvm//8u/If/+39SLf5Yl////7rGSQlq//qEuJwTeYNv/+MYZAkEzJ14AMOoAAPQBbgBgAAAXv2Jm6kPxl84t6goGZbyAIRHfwqCblPX5bVqy/1//Ulvut/Gf//9M1iFtX9F//YJwLo0/+MYZAYEgKtsAMUoAAMwBcRRgBAC/y4+KjD/FUsqmnf/oTTSgzAmAu//8hNZ1Hph3/4dAAggAA//////9v//qUxBTUUzLjEw/+MYZAgAAAGkAOAAAAAAA0gBwAAAMFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV"
		drum := "data:audio/mpeg;base64,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"
		// Do some arpeggio stuff here.
		{
			fn mod(x, y) {
				return ((x % y) + y) % y
			}
			fn arpeggiate(i, n) {
				r := floor(2*n - 2)
				return abs(mod(floor(i + 0.5*r), r) - 0.5*r)
			}
			// chords := ["Emaj7", "G#m7", "F#m7", "B7"] // Gone, gone
			// chords := ["C", "Dm"]
			// chords := ["Emaj7", "E7", "Amaj7", "C#m7", "F#m7", "B7"] // Thank you
			chords := ["A#m", "B#m", "A#", "Fm", "Gaug7"] // Thank you
			let chord_i = 0
			let chords_i = 0
			let chord = gchord(chords[chords_i])
			// thread.interval(fn() {
			// 	arpeggio_i := arpeggiate(chord_i, chord.length)
			// 	note_n := chord[arpeggio_i]
			// 	note := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"][mod(note_n, 12)]
			// 	// play_at_pitch(soft_middle, 1/440*freq_from_note(note + (3 + mod(floor(note_n/12), 4))))
			// 	play_at_pitch(soft_middle, 1/440*freq_from_note(note + (5 + mod(floor(note_n/12), 4))))
			// 	++chord_i
			// 	if chord_i == chord.length + 1 {
			// 		chord_i = 0
			// 		++chords_i
			// 		chords_i %= chords.length
			// 		chord = gchord(chords[chords_i])
			// 	}
			// }, 300)
			// Make the arpeggio reactive with key presses.
		}
		/*
		{
			let i = 0
			thread.interval(fn() {
				note := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"][i%12]
				play_at_pitch(drum, 1/440*freq_from_note(note + (3 + floor(i/12)%4)))
				++i
			}, 500)
		}
		*/
		/*
		{
			sequence := [
				["C3", "E3", "G3", "B3"],
				["F3", "A3", "C4", "E4"],
				["G3", "B3", "D4", "F4"],
				["C3", "E3", "G3", "B3"],
			]
			let i = 0
			thread.interval(fn() {
				while true {
				for const j in sequence[i] {
					play_at_pitch(soft_middle, 1/440*freq_from_note(sequence[i][j]))
				}
				play_at_pitch(drum, 1)
				++i
				i %= 4
			}, 1000)
		}
		play_at_pitch(easy_does_it, 0.2)
		*/
	}
}
