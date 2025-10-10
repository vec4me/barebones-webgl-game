teller_module := {}
{
    // モジュール全体で発話がブロックされるのを防ぐためのビジーフラグ
    let is_teller_busy = false
    // ブラウザから発話の許可を得たかどうかを示すフラグ
    let is_initialized = false

    fn teller_module.link(env) {
        thread := env.require("thread")
        let count = 0

        // 💡 ユーザー操作内で一度呼び出すことで発話の許可を得る
        fn teller_module.init() {
            if (is_initialized) {
                return;
            }

            // After you let speech synthesis api read a sentence, you're allowd to use that API.
            dummy_utterance := new speech_synthesis_utterance(" ");
            dummy_utterance.rate = 10.0
            speechSynthesis.speak(dummy_utterance);

            is_initialized = true;
        }


        fn teller_module.read(text) {

            if (!is_initialized) {
                console.error("Teller Error: Call teller_module.init() inside a user-triggered event (e.g., first W keydown).");
                return;
            }
            if (is_teller_busy) {
                return;
            }

            is_teller_busy = true
            let speak_requested = false

            utterance := new speech_synthesis_utterance(text);
            utterance.lang = "en-US"
            cps := 15
            utterance.rate = 1

            let speech_finished = false
            utterance.onend = function() {
                speech_finished = true
            }

            utterance.onerror = function(event) {
                console.error('SpeechSynthesis Error:', event.error)
                speech_finished = true
            };

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

            duration := text.length / cps

            lets_tell := thread.make(fn() {
                t := thread.now()
                e := t - lets_tell.t

                // 1) request for speech
                // 2) while running animation
                if (!speak_requested) {
                    speechSynthesis.speak(utterance);
                    speak_requested = true;
                }

                if e < duration {
                    label.style.max_width = (label.scroll_width * (e / duration)) + "px"
                }
                else if e < duration + 1 {
                    label.style.max_width = label.scroll_width + "px"
                    label.style.opacity = (1 - (e - duration)).to_fixed(2)
                }

                if (e >= duration + 1 && speech_finished) {
                    container.remove()
                    --count
                    is_teller_busy = false
                    lets_tell.remove()
                }
            })
        }

        // speech synthethis api object initialization should be checked
        // from caller of the teller.
        fn teller_module.get_initialized_state() {
            return is_initialized;
        }
    }
}
