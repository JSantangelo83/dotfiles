import { Astal, Gtk } from "ags/gtk4"

export default function Bar(monitor: any) {
  const barWidth = 40

  return (
    <window
      cssName="Bar"
      monitor={monitor}
      visible
      anchor={
        Astal.WindowAnchor.TOP |
        Astal.WindowAnchor.BOTTOM |
        Astal.WindowAnchor.LEFT
      }
      widthRequest={barWidth}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
    >
      <box
        vexpand
        orientation={Gtk.Orientation.VERTICAL}
        cssName="container"
      >
        <box cssName="top" />
        <box cssName="spacer" />
        <box vexpand cssName="stick" />
      </box>
    </window>
  )
}
