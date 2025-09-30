teller_module := {}
{
	fn teller_module.link(env) {
		thread := env.require("thread")
		let count = 0

		fn teller_module.read(text) {
			container := document.create_element("div")
			container.style = `
				position: fixed;
				bottom: ${15 + 10 * count}vh;
				width: 100%;
				text-align: center;
				pointer-events: none;
				z-index: 1;
			`

			label := document.create_element("span")
			label.text_content = text
			label.style = `
				display: inline-block;
				background: black;
				color: white;
				font-size: 2.5vh;
				white-space: nowrap;
				overflow: hidden;
				max-width: 0;
				opacity: 1;
			`

			container.append_child(label)
			document.body.append_child(container)
			++count

			cps := 30
			duration := text.length / cps

			lets_tell := thread.make(fn() {
				t := thread.now()
				e := t - lets_tell.t

				if e < duration {
					label.style.max_width = (label.scroll_width * (e / duration)) + "px"
				}
				else if e < duration + 1 {
					label.style.max_width = label.scroll_width + "px"
					label.style.opacity = (1 - (e - duration)).to_fixed(2)
				}
				else {
					container.remove()
					--count
					lets_tell.remove()
				}
			})
		}
	}
}

