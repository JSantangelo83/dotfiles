import { createState, createEffect } from "ags"
import { execAsync } from "ags/process"
import { Gtk } from "ags/gtk4"
import GLib from "gi://GLib"
import Gio from "gi://Gio"

const WLED_IP = "192.168.1.52"
const PRESETS_FILE = `${GLib.get_user_config_dir()}/ags-2.0/wled-presets.json`

type Rgb = { r: number; g: number; b: number }

const PRESETS: Array<{ name: string } & Rgb> = [
  { name: "Warm",   r: 255, g: 147, b: 41  },
  { name: "Cool",   r: 147, g: 197, b: 255 },
  { name: "Red",    r: 255, g: 50,  b: 50  },
  { name: "Green",  r: 50,  g: 220, b: 80  },
  { name: "Blue",   r: 60,  g: 120, b: 255 },
  { name: "Purple", r: 180, g: 60,  b: 255 },
]

// Load saved preset colors before any widget is built
function loadPresets() {
  try {
    const file = Gio.File.new_for_path(PRESETS_FILE)
    const [, bytes] = file.load_contents(null)
    const saved = JSON.parse(new TextDecoder().decode(bytes as unknown as Uint8Array))
    for (const p of PRESETS) {
      const s = saved[p.name]
      if (s && typeof s.r === "number") { p.r = s.r; p.g = s.g; p.b = s.b }
    }
  } catch {}
}

function savePresets() {
  try {
    const data: Record<string, Rgb> = {}
    for (const p of PRESETS) data[p.name] = { r: p.r, g: p.g, b: p.b }
    const file = Gio.File.new_for_path(PRESETS_FILE)
    try { file.get_parent()!.make_directory_with_parents(null) } catch {}
    const stream = file.replace(null, false, Gio.FileCreateFlags.REPLACE_DESTINATION, null)
    stream.write_all(new TextEncoder().encode(JSON.stringify(data)), null)
    stream.close(null)
  } catch (e) {
    console.error("wled: save presets:", e)
  }
}

loadPresets()

function rgbToHex(c: Rgb): string {
  return `#${c.r.toString(16).padStart(2, "0")}${c.g.toString(16).padStart(2, "0")}${c.b.toString(16).padStart(2, "0")}`
}

function wledPost(payload: object) {
  execAsync([
    "curl", "-sf", "-X", "POST",
    "-H", "Content-Type: application/json",
    "-d", JSON.stringify(payload),
    `http://${WLED_IP}/json/state`,
  ]).catch(console.error)
}

const [lastColor, setLastColor] = createState<Rgb | null>(null)
const [ambilightOn, setAmbilightOn] = createState(false)
const [pwrOn, setPwrOn] = createState(true)
const [lastBri, setLastBri] = createState(128)

function wledColor(c: Rgb) {
  setLastColor(c)
  wledPost({
    seg: [
      { id: 0, col: [[c.r, c.g, c.b]] },
      { id: 1, col: [[c.r, c.g, c.b]] },
    ],
  })
}

function hexToRgb(hex: string): Rgb | null {
  const m = hex.trim().replace(/^#/, "").match(/^([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i)
  if (!m) return null
  return { r: parseInt(m[1], 16), g: parseInt(m[2], 16), b: parseInt(m[3], 16) }
}

function initWledState() {
  execAsync(["systemctl", "--user", "is-active", "ambilight"])
    .then(() => setAmbilightOn(true))
    .catch(() => setAmbilightOn(false))

  execAsync(["curl", "-sf", `http://${WLED_IP}/json/state`])
    .then(s => {
      try {
        const st = JSON.parse(s)
        setPwrOn(st.on ?? true)
        setLastBri(st.bri ?? 128)
        const col = st.seg?.[0]?.col?.[0]
        if (Array.isArray(col) && col.length >= 3) {
          setLastColor({ r: col[0] as number, g: col[1] as number, b: col[2] as number })
        }
      } catch {}
    })
    .catch(() => {})
}
initWledState()

function buildPopover(parent: Gtk.Widget): Gtk.Popover {
  const pop = new Gtk.Popover()
  pop.set_parent(parent)
  pop.set_css_classes(["wled-popup"])
  pop.has_arrow = false

  const root = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 0 })
  root.set_css_classes(["wled-popover"])

  const hdr = new Gtk.Label({ label: "Led Control" })
  hdr.set_css_classes(["wled-title"])
  root.append(hdr)
  root.append(new Gtk.Separator())

  const ambRow = new Gtk.Box({ spacing: 8 })
  ambRow.set_css_classes(["wled-row"])
  const ambLbl = new Gtk.Label({ label: "Ambilight", hexpand: true, halign: Gtk.Align.START })
  ambLbl.set_css_classes(["wled-row-label", "wled-ambilight-label"])
  const ambSw = new Gtk.Switch()
  ambRow.append(ambLbl)
  ambRow.append(ambSw)
  root.append(ambRow)
  root.append(new Gtk.Separator())

  const controls = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 0 })

  const pwrRow = new Gtk.Box({ spacing: 8 })
  pwrRow.set_css_classes(["wled-row"])
  const pwrLbl = new Gtk.Label({ label: "Power", hexpand: true, halign: Gtk.Align.START })
  pwrLbl.set_css_classes(["wled-row-label"])
  const pwrSw = new Gtk.Switch()
  pwrRow.append(pwrLbl)
  pwrRow.append(pwrSw)
  controls.append(pwrRow)

  const briRow = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 4 })
  briRow.set_css_classes(["wled-row"])
  const briLbl = new Gtk.Label({ label: "Brightness", halign: Gtk.Align.START })
  briLbl.set_css_classes(["wled-row-label"])
  const briScale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 255, 1)
  briScale.draw_value = false
  briScale.hexpand = true
  briRow.append(briLbl)
  briRow.append(briScale)
  controls.append(briRow)

  const colHeaderRow = new Gtk.Box({ spacing: 8 })
  colHeaderRow.set_css_classes(["wled-row"])
  const colLbl = new Gtk.Label({ label: "Color", hexpand: true, halign: Gtk.Align.START })
  colLbl.set_css_classes(["wled-row-label"])
  colHeaderRow.append(colLbl)
  controls.append(colHeaderRow)

  // Hex entry created early so dot handlers can reference it
  const hexEntry = new Gtk.Entry({ placeholderText: "rrggbb", maxLength: 6, hexpand: true })
  hexEntry.set_css_classes(["wled-hex-entry"])

  // Preset dots — each gets its own CSS provider so colors can be rewritten dynamically
  const dotRefs: Array<{ btn: Gtk.Button; provider: Gtk.CssProvider }> = []
  let selectedDotIdx: number | null = null

  function applyDotColor(idx: number) {
    const p = PRESETS[idx]
    dotRefs[idx].provider.load_from_string(
      `button { background-color: rgb(${p.r},${p.g},${p.b}); }`
    )
  }

  const colDotsRow = new Gtk.Box({ spacing: 0 })
  colDotsRow.set_css_classes(["wled-row"])
  const colBox = new Gtk.Box({ spacing: 5, halign: Gtk.Align.CENTER, hexpand: true })

  for (let i = 0; i < PRESETS.length; i++) {
    const p = PRESETS[i]
    const btn = new Gtk.Button()
    btn.set_css_classes(["color-dot"])
    btn.tooltip_text = p.name

    const dotProvider = new Gtk.CssProvider()
    btn.get_style_context().add_provider(dotProvider, Gtk.STYLE_PROVIDER_PRIORITY_USER + 1)
    dotRefs.push({ btn, provider: dotProvider })
    applyDotColor(i)

    const idx = i
    btn.connect("clicked", () => {
      if (selectedDotIdx !== null) dotRefs[selectedDotIdx].btn.remove_css_class("dot-selected")
      selectedDotIdx = idx
      btn.add_css_class("dot-selected")
      hexEntry.set_text(rgbToHex(p).slice(1))
      wledColor(p)
    })
    colBox.append(btn)
  }

  colDotsRow.append(colBox)
  controls.append(colDotsRow)

  // Hex row
  const hexRow = new Gtk.Box({ spacing: 6 })
  hexRow.set_css_classes(["wled-row"])
  const hexHash = new Gtk.Label({ label: "#" })
  hexHash.set_css_classes(["wled-row-label"])
  const hexApply = new Gtk.Button()
  hexApply.set_css_classes(["wled-icon-btn"])
  hexApply.label = "→"
  hexApply.tooltip_text = "Apply hex color"

  const applyHex = () => {
    const c = hexToRgb(hexEntry.get_text())
    if (!c) { hexEntry.add_css_class("wled-hex-error"); return }

    // If a dot is selected, permanently reassign its color
    if (selectedDotIdx !== null) {
      const p = PRESETS[selectedDotIdx]
      p.r = c.r; p.g = c.g; p.b = c.b
      applyDotColor(selectedDotIdx)
      savePresets()
    }

    wledColor(c)
    hexEntry.set_text("")
  }

  hexEntry.connect("activate", applyHex)
  hexEntry.connect("changed", () => hexEntry.remove_css_class("wled-hex-error"))
  hexApply.connect("clicked", applyHex)
  hexRow.append(hexHash)
  hexRow.append(hexEntry)
  hexRow.append(hexApply)
  controls.append(hexRow)

  const setAmbilightControls = (ambOn: boolean) => {
    pwrRow.set_sensitive(!ambOn)
    colHeaderRow.set_sensitive(!ambOn)
    colDotsRow.set_sensitive(!ambOn)
    hexRow.set_sensitive(!ambOn)
  }

  root.append(controls)
  pop.set_child(root)

  let briDebounce = 0
  let syncingFromFetch = false
  pop.connect("notify::visible", () => {
    if (!pop.visible) return

    execAsync(["systemctl", "--user", "is-active", "ambilight"])
      .then(() => { setAmbilightOn(true); syncingFromFetch = true; ambSw.set_active(true); syncingFromFetch = false; setAmbilightControls(true) })
      .catch(() => { setAmbilightOn(false); syncingFromFetch = true; ambSw.set_active(false); syncingFromFetch = false; setAmbilightControls(false) })

    execAsync(["curl", "-sf", `http://${WLED_IP}/json/state`])
      .then(s => {
        try {
          const st = JSON.parse(s)
          const on = st.on ?? true
          const bri = st.bri ?? 128
          syncingFromFetch = true
          pwrSw.set_active(on)
          briScale.set_value(Math.round(Math.pow(bri / 255, 1 / 2.2) * 255))
          syncingFromFetch = false
          setPwrOn(on)
          setLastBri(bri)
          const col = st.seg?.[0]?.col?.[0]
          if (Array.isArray(col) && col.length >= 3) {
            setLastColor({ r: col[0] as number, g: col[1] as number, b: col[2] as number })
          }
        } catch {}
      })
      .catch(() => {})
  })

  pwrSw.connect("state-set", (_: Gtk.Switch, state: boolean) => {
    if (syncingFromFetch) return false
    setPwrOn(state)
    wledPost({ on: state })
    return false
  })

  briScale.connect("value-changed", () => {
    if (syncingFromFetch) return
    const linear = Math.round(Math.pow(briScale.get_value() / 255, 2.2) * 255)
    setLastBri(Math.max(1, linear))
    if (briDebounce) GLib.source_remove(briDebounce)
    briDebounce = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 80, () => {
      wledPost({ bri: Math.max(1, Math.round(Math.pow(briScale.get_value() / 255, 2.2) * 255)) })
      briDebounce = 0
      return GLib.SOURCE_REMOVE
    })
  })

  ambSw.connect("state-set", (_: Gtk.Switch, state: boolean) => {
    if (syncingFromFetch) return false
    setAmbilightOn(state)
    setAmbilightControls(state)
    execAsync(["systemctl", "--user", state ? "start" : "stop", "ambilight"])
      .catch(console.error)
    return false
  })

  return pop
}

export default function WledButton() {
  return (
    <button
      class="wled-button flat"
      tooltipText="Led Control"
      $={(btn: Gtk.Button) => {
        const lbl = new Gtk.Label({ label: "󰌵" })
        lbl.set_css_classes(["wled-icon"])
        btn.set_child(lbl)

        const colorProvider = new Gtk.CssProvider()
        lbl.get_style_context().add_provider(colorProvider, Gtk.STYLE_PROVIDER_PRIORITY_USER + 1)

        createEffect(() => {
          const amb = ambilightOn()
          const on = pwrOn()
          const bri = lastBri()
          const color = lastColor()

          if (amb) {
            lbl.label = "󰌵"
            lbl.set_css_classes(["wled-icon", "wled-ambilight"])
            colorProvider.load_from_string("")
          } else if (!on || bri === 0) {
            lbl.label = "󰌶"
            lbl.set_css_classes(["wled-icon"])
            colorProvider.load_from_string("")
          } else {
            lbl.label = "󰌵"
            lbl.set_css_classes(["wled-icon"])
            colorProvider.load_from_string(
              color ? `label { color: rgb(${color.r},${color.g},${color.b}); }` : ""
            )
          }
        })

        const pop = buildPopover(btn)
        btn.connect("clicked", () => pop.popup())
      }}
    />
  )
}
