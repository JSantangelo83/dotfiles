import app from "ags/gtk4/app"
import { For, This, createState } from "ags"
import { Gdk } from "ags/gtk4"
import style from "./style.scss"
import Bar from "./widget/Bar"
import { initTheme, getConfig } from "./jsbar"

// The bar lives only on the configured monitor (jsbar.jsonc "monitor").
// <For> destroys the window when that monitor disappears and re-creates it
// when it comes back. A freshly (re)connected Gdk.Monitor has an empty
// connector for a moment, so re-sync on notify::connector too.
const [primary, setPrimary] = createState<Gdk.Monitor[]>([])

function sync() {
  setPrimary(app.monitors.filter((m) => m.connector === getConfig().monitor))
}

app.start({
  css: style,
  main() {
    initTheme()
    const monitors = Gdk.Display.get_default()!.get_monitors()
    monitors.connect("items-changed", (_, pos: number, _rem: number, added: number) => {
      for (let i = 0; i < added; i++) {
        const mon = monitors.get_item(pos + i) as Gdk.Monitor
        if (!mon.connector) mon.connect("notify::connector", sync)
      }
      sync()
    })
    sync()
    return (
      <For each={primary}>
        {(monitor) => (
          <This this={app}>
            <Bar gdkmonitor={monitor} />
          </This>
        )}
      </For>
    )
  },
})
