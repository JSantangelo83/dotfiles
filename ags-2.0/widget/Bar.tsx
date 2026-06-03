import { Astal, Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import AstalHyprland from "gi://AstalHyprland"
import Head from "./Head"
import Clock from "./Clock"
import Battery from "./Battery"
import Tray from "./Tray"
import { WorkspacesContainer } from "./Workspace"
import WledButton from "./WledController"
import SysMetrics from "./SysMetrics"

const { TOP, BOTTOM, LEFT } = Astal.WindowAnchor
const SEPARATION = 10

const hyprland = AstalHyprland.get_default()

function HPercentage(pct: number) {
  return Math.round(pct / 100 * (hyprland.get_monitor(0)?.height ?? 1440))
}

execAsync(["bash", `${SRC}/scripts/setup-icons.sh`, SRC]).catch(console.error)

export default function Bar(monitor: number) {
  return (
    <window
      monitor={monitor}
      name={`bar${monitor}`}
      anchor={TOP | BOTTOM | LEFT}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      css="background: transparent;"
      marginTop={HPercentage(1)}
      marginBottom={HPercentage(1)}
      marginLeft={HPercentage(1)}
    >
      <box orientation={1} spacing={SEPARATION}>
        <Head />
        {/* bar column narrower than head — halign CENTER keeps it at natural width */}
        <box orientation={1} class="bar" vexpand halign={Gtk.Align.CENTER}>
          <WorkspacesContainer />
          <box class="wled-section" orientation={1} halign={Gtk.Align.CENTER}>
            <WledButton />
            <SysMetrics />
          </box>
          <box vexpand />
          <box orientation={1} spacing={SEPARATION}>
            <Tray />
            <Clock />
            <Battery />
          </box>
        </box>
      </box>
    </window>
  )
}
