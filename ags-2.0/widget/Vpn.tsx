import { createState, createEffect } from "ags"
import { Gtk } from "ags/gtk4"
import GLib from "gi://GLib"
import { execAsync, subprocess } from "ags/process"

type Vpn = { name: string; active: boolean }

const ICON_ON  = `${SRC}/assets/vpn-connected.png`
const ICON_OFF = `${SRC}/assets/vpn-disconnected.png`

// NetworkManager connection types that count as a VPN
const VPN_TYPES = new Set(["vpn", "wireguard"])

const [vpns, setVpns] = createState<Vpn[]>([])
const [pending, setPending] = createState<string | null>(null)

// nmcli -t escapes ':' inside fields as '\:'
function splitTerse(line: string): string[] {
  return line.split(/(?<!\\):/).map(f => f.replace(/\\:/g, ":"))
}

function fetchVpns() {
  execAsync(["nmcli", "-t", "-f", "NAME,TYPE,ACTIVE", "connection", "show"])
    .then(out => {
      const list = out.trim().split("\n").filter(Boolean)
        .map(splitTerse)
        .filter(([, type]) => VPN_TYPES.has(type))
        .map(([name, , active]) => ({ name, active: active === "yes" }))
      setVpns(list)
    })
    .catch(console.error)
}

// Refresh on any NetworkManager change instead of polling (debounced, the monitor is chatty)
fetchVpns()
let monitorDebounce = 0
subprocess(["nmcli", "monitor"], () => {
  if (monitorDebounce) GLib.source_remove(monitorDebounce)
  monitorDebounce = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 300, () => {
    fetchVpns()
    monitorDebounce = 0
    return GLib.SOURCE_REMOVE
  })
}, () => {})

// Bring every other active VPN down, then the target up (null = all off)
async function switchTo(target: string | null) {
  setPending(target ?? "")
  try {
    for (const v of vpns.peek()) {
      if (v.active && v.name !== target)
        await execAsync(["nmcli", "connection", "down", v.name])
    }
    if (target) await execAsync(["nmcli", "connection", "up", target])
  } catch (e) {
    execAsync(["notify-send", "-a", "VPN", "VPN", `${e}`]).catch(() => {})
  } finally {
    setPending(null)
    fetchVpns()
  }
}

function clearBox(box: Gtk.Box) {
  let child = box.get_first_child()
  while (child) {
    const next = child.get_next_sibling()
    box.remove(child)
    child = next
  }
}

function buildPopover(parent: Gtk.Widget): Gtk.Popover {
  const pop = new Gtk.Popover()
  pop.set_parent(parent)
  pop.set_css_classes(["wled-popup"])
  pop.has_arrow = false

  const root = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 0 })
  root.set_css_classes(["vpn-popover"])

  const hdr = new Gtk.Label({ label: "VPN" })
  hdr.set_css_classes(["wled-title"])
  root.append(hdr)
  root.append(new Gtk.Separator())

  const list = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 0 })
  list.set_css_classes(["vpn-list"])
  root.append(list)
  pop.set_child(root)

  let checks = new Map<string | null, Gtk.CheckButton>()
  let syncing = false

  function addRow(label: string, target: string | null, group: Gtk.CheckButton | null) {
    const row = new Gtk.Box({ spacing: 0 })
    row.set_css_classes(["audio-device-row"])

    const lbl = new Gtk.Label({ label, hexpand: true, halign: Gtk.Align.START })
    lbl.set_css_classes(target ? ["audio-device-name"] : ["audio-device-name", "vpn-off-label"])

    const check = new Gtk.CheckButton()
    check.set_css_classes(["audio-check"])
    if (group) check.set_group(group)

    check.connect("notify::active", () => {
      if (syncing || !check.active) return
      switchTo(target)
    })

    // Clicking anywhere on the row selects it, not just the radio
    const click = new Gtk.GestureClick()
    click.connect("released", () => { check.active = true })
    row.add_controller(click)
    row.set_cursor_from_name("pointer")

    row.append(lbl)
    row.append(check)
    list.append(row)
    checks.set(target, check)
    return check
  }

  function rebuild(items: Vpn[]) {
    clearBox(list)
    checks = new Map()
    const off = addRow("Off", null, null)
    for (const v of items) addRow(v.name, v.name, off)
    sync(items)
  }

  // Reflect real state without triggering switchTo
  function sync(items: Vpn[]) {
    const active = items.find(v => v.active)?.name ?? null
    syncing = true
    const check = checks.get(active)
    if (check) check.active = true
    syncing = false
  }

  createEffect(() => {
    const items = vpns()
    const names = items.map(v => v.name)
    const same = names.length === checks.size - 1 && names.every(n => checks.has(n))
    if (same) sync(items)
    else rebuild(items)
  })

  createEffect(() => {
    const busy = pending() !== null
    for (const c of checks.values()) c.sensitive = !busy
  })

  pop.connect("notify::visible", () => {
    if (pop.visible) fetchVpns()
  })

  return pop
}

export default function VpnButton() {
  return (
    <button
      class="wled-button flat"
      tooltipText="VPN"
      $={(btn: Gtk.Button) => {
        const img = new Gtk.Image({ file: ICON_OFF, pixelSize: 30 })
        img.set_css_classes(["vpn-icon"])
        btn.set_child(img)

        createEffect(() => {
          const active = vpns().find(v => v.active)
          const busy   = pending() !== null
          const cls    = busy ? "vpn-pending" : active ? "vpn-on" : ""
          img.set_from_file(active ? ICON_ON : ICON_OFF)
          img.set_css_classes(cls ? ["vpn-icon", cls] : ["vpn-icon"])
          btn.tooltipText = busy ? "VPN: switching…" : active ? `VPN: ${active.name}` : "VPN: off"
        })

        const pop = buildPopover(btn)
        btn.connect("clicked", () => pop.popup())
      }}
    />
  )
}
