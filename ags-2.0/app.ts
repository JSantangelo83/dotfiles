import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./widget/Bar"
import { Astal } from "ags/gtk4"
import Gdk from "gi://Gdk"

const PRIMARY_CONNECTOR = "DP-1"

let barWindow: ReturnType<typeof Bar> | null = null

function findPrimaryGdkMonitor(): Gdk.Monitor | null {
  const display = Gdk.Display.get_default()
  if (!display) return null
  const monitors = display.get_monitors()
  for (let i = 0; i < monitors.get_n_items(); i++) {
    const mon = monitors.get_item(i) as Gdk.Monitor
    if (mon?.get_connector() === PRIMARY_CONNECTOR) return mon
  }
  return null
}

function updateBar() {
  const mon = findPrimaryGdkMonitor()
  if (mon && !barWindow) {
    barWindow = Bar(0)
    ;(barWindow as any).gdkmonitor = mon
    barWindow.present()
  } else if (!mon && barWindow) {
    barWindow.destroy()
    barWindow = null
  }
}

app.start({
  css: style,
  main() {
    updateBar()
    const display = Gdk.Display.get_default()!
    display.get_monitors().connect("items-changed", updateBar)
  },
})
