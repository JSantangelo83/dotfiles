import { createPoll } from "ags/time"
import { Gtk } from "ags/gtk4"

const hour = createPoll("", 1000, "date +%H")
const min  = createPoll("", 1000, "date +%M")
const date = createPoll("", 60000, 'date "+%A %d %B"')

function HourMin(label: string, value: ReturnType<typeof createPoll>) {
  return (
    <box>
      <label class="hourmin" label={value} />
      <box orientation={1} valign={Gtk.Align.CENTER} class="label">
        <label label={label[0]} />
        <label label={label[1]} />
      </box>
    </box>
  )
}

export default function Clock() {
  return (
    <box class="clock-element container" hexpand tooltipText={date}>
      <box orientation={1} halign={Gtk.Align.CENTER} hexpand>
        {HourMin("hs", hour)}
        {HourMin("mn", min)}
      </box>
    </box>
  )
}
