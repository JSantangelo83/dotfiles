import { Astal, Gtk, Gdk } from "ags/gtk4"
import { onCleanup, createBinding } from "ags"
import { execAsync } from "ags/process"
import Head from "./Head"
import Clock from "./Clock"
import Battery from "./Battery"
import Tray from "./Tray"
import { WorkspacesContainer } from "./Workspace"
import WledButton from "./WledController"
import SysMetrics from "./SysMetrics"
import { getConfig } from "../jsbar"

const { TOP, BOTTOM, LEFT } = Astal.WindowAnchor

execAsync(["bash", `${SRC}/scripts/setup-icons.sh`, SRC]).catch(console.error)

export default function Bar({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const cfg    = getConfig()
  const w      = cfg.widgets
  // geometry is empty right after the monitor (re)connects, so bind to it
  const margin = createBinding(gdkmonitor, "geometry").as((g) =>
    Math.round(cfg.barMarginsPercent / 100 * g.height),
  )

  return (
    <window
      visible
      name="bar"
      gdkmonitor={gdkmonitor}
      anchor={TOP | BOTTOM | LEFT}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      css="background: transparent;"
      marginTop={margin}
      marginBottom={margin}
      marginLeft={margin}
      $={(self) => onCleanup(() => self.destroy())}
    >
      <box orientation={1} spacing={cfg.barGap}>
        <Head />
        <box orientation={1} class="bar" vexpand halign={Gtk.Align.CENTER}>
          {w.workspaces && WorkspacesContainer()}
          <box class="wled-section" orientation={1}>
            <box halign={Gtk.Align.CENTER}>
              {w.sysmetrics && SysMetrics()}
            </box>
          </box>
          <box vexpand />
          <box orientation={1} spacing={cfg.barGap}>
            {w.tray    && Tray()}
            {w.clock   && Clock()}
            {w.wled    && WledButton()}
            {w.battery && Battery()}
          </box>
        </box>
      </box>
    </window>
  )
}
