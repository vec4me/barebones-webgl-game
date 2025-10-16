debug_module := {}
{
	debug_module.log = console.log
	fn debug_module.link(env) {
		fn debug_module.bench(name) {
			debug := {}
			t0 := performance.now()
			fn debug.end() {
				t1 := performance.now()
				debug_module.log("${name}:", t1 - t0, "ms")
			}
			return debug
		}
	}
    fn debug_module.panel(param) {
       document.querySelector("body").innerHTML+=`
           <dialog id="debug_panel">
             <div class="panel-grid">
               <div class="panel-header">デバッグパネル</div>
               <button type="button" onclick="location.reload()">リロード</button>
               ${
               Object.keys(param).map(p=>{
               return `
                  <div class="panel-body">
                  ${p}
                  <input type="range" min="0" max="100" value=${param[p]} id="volume">
                  </div>
               `
               }).join('')
               }
               <button type="button" onclick="alert('みたいな機能をつくってみたいよね')">この場所を記憶</button>
               <button type="button" onclick="play">音楽再生</button>
             </div>
           </dialog>
         `
       panel := document.getElementById("debug_panel") ;
       panel.open ? panel.close():panel.showModal()
   }
}
