import { createState, createEffect } from "ags"
import { execAsync } from "ags/process"
import { Gtk } from "ags/gtk4"
import GLib from "gi://GLib"

type Device = { id: string; name: string; active: boolean }

const [volume, setVolume] = createState(0)
const [muted, setMuted] = createState(false)

function parseSection(status: string, section: "Sinks" | "Sources"): Device[] {
  const devices: Device[] = []
  const lines = status.split("\n")
  let inSection = false

  for (const line of lines) {
    if (line.includes(`${section}:`)) { inSection = true; continue }
    if (!inSection) continue
    const m = line.match(/│\s+(\*\s+)?(\d+)\.\s+(.+?)\s+\[/)
    if (m) devices.push({ active: !!m[1], id: m[2], name: m[3].trim() })
    else if (devices.length > 0 && (line.includes("├─") || line.includes("└─"))) break
  }
  return devices.slice(0, 3)
}

function fetchVolume() {
  execAsync(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
    .then(s => {
      const m = s.match(/Volume: ([\d.]+)(\s+\[MUTED\])?/)
      if (m) { setVolume(parseFloat(m[1])); setMuted(!!m[2]) }
    })
    .catch(console.error)
}

fetchVolume()
GLib.timeout_add(GLib.PRIORITY_DEFAULT, 3000, () => {
  fetchVolume()
  return GLib.SOURCE_CONTINUE
})

function volIcon(vol: number, mut: boolean): string {
  if (mut || vol === 0) return "󰝟"
  if (vol < 0.33) return "󰕿"
  if (vol < 0.66) return "󰖀"
  return "󰕾"
}

function clearBox(box: Gtk.Box) {
  let child = box.get_first_child()
  while (child) {
    const next = child.get_next_sibling()
    box.remove(child)
    child = next
  }
}

function buildDeviceList(container: Gtk.Box, devices: Device[]) {
  clearBox(container)
  let firstCheck: Gtk.CheckButton | null = null

  for (const device of devices) {
    const row = new Gtk.Box({ spacing: 0 })
    row.set_css_classes(["audio-device-row"])

    const name = device.name.length > 22 ? device.name.slice(0, 20) + "…" : device.name
    const lbl = new Gtk.Label({ label: name, hexpand: true, halign: Gtk.Align.START })
    lbl.set_css_classes(["audio-device-name"])

    const check = new Gtk.CheckButton()
    check.set_css_classes(["audio-check"])
    if (firstCheck) check.set_group(firstCheck)
    else firstCheck = check
    check.active = device.active

    const id = device.id
    check.connect("notify::active", () => {
      if (!check.active) return
      execAsync(["wpctl", "set-default", id]).catch(console.error)
      fetchVolume()
    })

    row.append(lbl)
    row.append(check)
    container.append(row)
  }
}

function buildPopover(parent: Gtk.Widget): Gtk.Popover {
  const pop = new Gtk.Popover()
  pop.set_parent(parent)
  pop.set_css_classes(["wled-popup"])
  pop.has_arrow = false

  const root = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 0 })
  root.set_css_classes(["audio-popover"])

  const hdr = new Gtk.Label({ label: "Audio" })
  hdr.set_css_classes(["wled-title"])
  root.append(hdr)
  root.append(new Gtk.Separator())

  // Volume row
  const volRow = new Gtk.Box({ spacing: 8 })
  volRow.set_css_classes(["wled-row"])

  const muteBtn = new Gtk.Button()
  muteBtn.set_css_classes(["wled-icon-btn", "audio-mute-btn"])
  const muteIcon = new Gtk.Label({ label: "󰕾" })
  muteIcon.set_css_classes(["audio-icon"])
  muteBtn.set_child(muteIcon)

  const volScale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 1.5, 0.01)
  volScale.draw_value = false
  volScale.hexpand = true
  volScale.add_mark(1.0, Gtk.PositionType.BOTTOM, null)

  volRow.append(muteBtn)
  volRow.append(volScale)
  root.append(volRow)
  root.append(new Gtk.Separator())

  // Device columns
  const cols = new Gtk.Box({ spacing: 0 })

  const srcCol = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 0, hexpand: true })
  const colSep = new Gtk.Separator()
  colSep.orientation = Gtk.Orientation.VERTICAL
  const snkCol = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 0, hexpand: true })

  const inHdr = new Gtk.Label({ label: "INPUT" })
  inHdr.set_css_classes(["audio-col-header"])
  inHdr.halign = Gtk.Align.START

  const outHdr = new Gtk.Label({ label: "OUTPUT" })
  outHdr.set_css_classes(["audio-col-header"])
  outHdr.halign = Gtk.Align.START

  const srcList = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 0 })
  const snkList = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 0 })

  srcCol.append(inHdr)
  srcCol.append(srcList)
  snkCol.append(outHdr)
  snkCol.append(snkList)

  cols.append(srcCol)
  cols.append(colSep)
  cols.append(snkCol)
  root.append(cols)

  pop.set_child(root)

  let syncingVol = false

  createEffect(() => {
    const vol = volume()
    const mut = muted()
    syncingVol = true
    volScale.set_value(vol)
    syncingVol = false
    muteIcon.label = volIcon(vol, mut)
    if (mut || vol === 0) muteIcon.add_css_class("audio-muted")
    else muteIcon.remove_css_class("audio-muted")
  })

  let volDebounce = 0
  volScale.connect("value-changed", () => {
    if (syncingVol) return
    const val = volScale.get_value()
    setVolume(val)
    if (volDebounce) GLib.source_remove(volDebounce)
    volDebounce = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 80, () => {
      execAsync(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.min(1.5, val).toFixed(2)])
        .catch(console.error)
      volDebounce = 0
      return GLib.SOURCE_REMOVE
    })
  })

  muteBtn.connect("clicked", () => {
    execAsync(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
      .then(() => fetchVolume())
      .catch(console.error)
  })

  pop.connect("notify::visible", () => {
    if (!pop.visible) return
    fetchVolume()
    execAsync(["wpctl", "status"])
      .then(s => {
        buildDeviceList(srcList, parseSection(s, "Sources"))
        buildDeviceList(snkList, parseSection(s, "Sinks"))
      })
      .catch(console.error)
  })

  return pop
}

export default function AudioButton() {
  return (
    <button
      class="wled-button flat"
      tooltipText="Audio"
      $={(btn: Gtk.Button) => {
        const lbl = new Gtk.Label({ label: "󰕾" })
        lbl.set_css_classes(["wled-icon"])
        btn.set_child(lbl)

        createEffect(() => {
          lbl.label = volIcon(volume(), muted())
        })

        const pop = buildPopover(btn)
        btn.connect("clicked", () => pop.popup())
      }}
    />
  )
}
