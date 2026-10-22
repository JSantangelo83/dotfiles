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
import { getConfig } from "../jsbar"

const { TOP, BOTTOM, LEFT } = Astal.WindowAnchor

const hyprland = AstalHyprland.get_default()

function HPercentage(pct: number) {
  return Math.round(pct / 100 * (hyprland.get_monitor(0)?.height ?? 1440))
}

execAsync(["bash", `${SRC}/scripts/setup-icons.sh`, SRC]).catch(console.error)

export default function Bar(monitor: number) {
  const cfg = getConfig()
  const w   = cfg.widgets

  return (
    <window
      monitor={monitor}
      name={`bar${monitor}`}
      anchor={TOP | BOTTOM | LEFT}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      css="background: transparent;"
      marginTop={HPercentage(cfg.barMarginsPercent)}
      marginBottom={HPercentage(cfg.barMarginsPercent)}
      marginLeft={HPercentage(cfg.barMarginsPercent)}
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
