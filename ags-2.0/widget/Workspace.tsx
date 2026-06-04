import { createBinding, createComputed, createEffect, createState, onCleanup } from "ags"
import { readFile, monitorFile } from "ags/file"
import { execAsync } from "ags/process"
import { Gtk } from "ags/gtk4"
import AstalHyprland from "gi://AstalHyprland"
import GLib from "gi://GLib"
import Gio from "gi://Gio"

const hyprland = AstalHyprland.get_default()

const WORKSPACES = 8
const ICON_SIZE = 20

interface Settings {
  icons_dir: string
  workspaces: Record<number, { icon: string }>
}

const settingsPath = `${SRC}/default-settings.json`
let _settings: Settings = { icons_dir: "/tmp", workspaces: {} }
try { _settings = JSON.parse(readFile(settingsPath)) } catch {}
monitorFile(settingsPath, () => {
  try { _settings = JSON.parse(readFile(settingsPath)) } catch {}
})

const getIconsDir = () => _settings?.icons_dir ?? "/tmp"

const ICONS_FILE = `${GLib.get_user_config_dir()}/ags-2.0/workspace-icons.json`

function loadIconOverrides(): Record<number, string> {
  try {
    const file = Gio.File.new_for_path(ICONS_FILE)
    const [, bytes] = file.load_contents(null)
    return JSON.parse(new TextDecoder().decode(bytes as unknown as Uint8Array))
  } catch {
    return {}
  }
}

function saveIconOverrides(overrides: Record<number, string>) {
  try {
    const file = Gio.File.new_for_path(ICONS_FILE)
    try { file.get_parent()!.make_directory_with_parents(null) } catch {}
    const stream = file.replace(null, false, Gio.FileCreateFlags.REPLACE_DESTINATION, null)
    stream.write_all(new TextEncoder().encode(JSON.stringify(overrides)), null)
    stream.close(null)
  } catch (e) {
    console.error("workspace: save icons:", e)
  }
}

const [iconOverrides, setIconOverrides] = createState<Record<number, string>>(loadIconOverrides())

export function setWorkspaceIcon(wsId: number, icon: string) {
  const next = { ...iconOverrides(), [wsId]: icon }
  setIconOverrides(next)
  saveIconOverrides(next)
}

function getIcon(id: number) {
  return iconOverrides()[id] ?? _settings?.workspaces?.[id]?.icon ?? "any"
}

const workspaces = createBinding(hyprland, "workspaces")
const clients    = createBinding(hyprland, "clients")

const monitorWsBindings = hyprland.get_monitors().map(m => ({
  monId: m.id as number,
  activeWs: createBinding(m, "active-workspace"),
}))

function changeWorkspace(id: number) {
  hyprland.message_async(`dispatch hl.dsp.focus({ workspace = ${id} })`, () => {})
}

// ── Icon picker popover ────────────────────────────────────────────────────

interface IconEntry { key: string; path0: string }

let cachedIcons: IconEntry[] | null = null

async function loadIcons(): Promise<IconEntry[]> {
  if (cachedIcons) return cachedIcons
  try {
    const dir = getIconsDir()
    const out = await execAsync(["bash", "-c", `find "${dir}" -name "*-0.png" | sort`])
    cachedIcons = out.trim().split("\n").filter(Boolean).map(p => {
      const rel = p.replace(dir + "/", "").replace(/-0\.png$/, "")
      return { key: rel, path0: p }
    })
    return cachedIcons
  } catch { return [] }
}

function buildIconPicker(wsId: number, parent: Gtk.Widget): Gtk.Popover {
  const pop = new Gtk.Popover()
  pop.set_parent(parent)
  pop.set_css_classes(["wled-popup"])
  pop.has_arrow = false

  const root = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 6 })
  root.set_css_classes(["icon-picker"])
  root.set_size_request(140, -1)

  const search = new Gtk.Entry({ placeholderText: "search…", hexpand: true })
  search.set_css_classes(["icon-search"])
  root.append(search)

  const scroll = new Gtk.ScrolledWindow()
  scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
  scroll.set_min_content_height(240)
  scroll.set_max_content_height(400)

  const flow = new Gtk.FlowBox({
    maxChildrenPerLine: 3,
    minChildrenPerLine: 3,
    selectionMode: Gtk.SelectionMode.NONE,
    homogeneous: true,
    rowSpacing: 4,
    columnSpacing: 4,
    halign: Gtk.Align.CENTER,
  })
  flow.set_css_classes(["icon-flow"])
  scroll.set_child(flow)
  root.append(scroll)

  pop.set_child(root)

  let allIcons: IconEntry[] = []

  function populate(filter: string) {
    let ch = flow.get_first_child()
    while (ch) { const nx = ch.get_next_sibling(); flow.remove(ch); ch = nx }

    const lower = filter.toLowerCase()
    const filtered = filter ? allIcons.filter(e => e.key.toLowerCase().includes(lower)) : allIcons

    for (const entry of filtered) {
      const btn = new Gtk.Button()
      btn.set_css_classes(["icon-pick-btn"])
      const img = new Gtk.Image()
      img.set_pixel_size(28)
      img.set_from_file(entry.path0)
      btn.set_child(img)

      btn.connect("clicked", () => {
        setWorkspaceIcon(wsId, entry.key)
        pop.popdown()
      })
      flow.append(btn)
    }
  }

  pop.connect("notify::visible", () => {
    if (!pop.visible) return
    loadIcons().then(icons => {
      allIcons = icons
      populate(search.get_text())
      search.grab_focus()
    })
  })

  let debounce = 0
  search.connect("changed", () => {
    if (debounce) GLib.source_remove(debounce)
    debounce = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 120, () => {
      populate(search.get_text())
      debounce = 0
      return GLib.SOURCE_REMOVE
    })
  })

  return pop
}

// ── Workspace button ───────────────────────────────────────────────────────

function Workspace(id: number) {
  const windowCount = createComputed(() =>
    clients().filter(c => c.workspace?.id === id).length
  )

  const iconFile = createComputed(() => {
    const icon = getIcon(id)
    // depend on overrides reactively
    const _ = iconOverrides()
    const hasWindows = windowCount() > 0
    return `${getIconsDir()}/${icon}-${hasWindows ? 1 : 0}.png`
  })

  const hasUrgent = createComputed(() =>
    clients().some(c => c.urgent && c.workspace?.id === id)
  )

  // Sorted list of sub-workspace IDs currently alive for this main workspace.
  // Sub-workspaces use the encoding: id*10+N (e.g. ws 2 → 21, 22, …)
  const subIds = createComputed((): number[] =>
    workspaces()
      .filter(ws => ws.id > 9 && Math.floor(ws.id / 10) === id)
      .map(ws => ws.id)
      .sort((a, b) => a - b)
  )

  // Which sub-workspace (if any) is currently active on any monitor for this group.
  const activeSub = createComputed((): { subId: number; monId: number } | null => {
    for (const { monId, activeWs } of monitorWsBindings) {
      const wsId = activeWs()?.id
      if (wsId !== undefined && wsId > 9 && Math.floor(wsId / 10) === id)
        return { subId: wsId, monId }
    }
    return null
  })

  // Underline class: only show for the MAIN workspace, not for sub-workspaces.
  const monitorClass = createComputed(() => {
    const match = monitorWsBindings.find(({ activeWs }) => activeWs()?.id === id)
    return `item monitor-${match ? match.monId : "none"}`
  })

  return (
    <box class="ws-item-wrap" orientation={Gtk.Orientation.VERTICAL}
      $={(wrap: Gtk.Box) => {
        // ── Button ──────────────────────────────────────────────────────────
        const btn = new Gtk.Button()
        createEffect(() => btn.set_css_classes(monitorClass().split(" ")))
        btn.connect("clicked", () => changeWorkspace(id))

        const overlay = new Gtk.Overlay()

        const img = new Gtk.Image()
        img.set_css_classes(["icon"])
        img.set_pixel_size(ICON_SIZE)
        img.halign = Gtk.Align.CENTER
        img.valign = Gtk.Align.CENTER
        overlay.set_child(img)
        createEffect(() => img.set_from_file(iconFile()))

        const badge = new Gtk.Label()
        badge.set_css_classes(["label"])
        badge.halign = Gtk.Align.END
        badge.valign = Gtk.Align.END
        overlay.add_overlay(badge)

        const refreshOnMove = () => {
          const n = clients.peek().filter((c: any) => c.workspace?.id === id).length
          badge.label = `${n}`
          badge.visible = n > 0
          const icon = getIcon(id)
          img.set_from_file(`${getIconsDir()}/${icon}-${n > 0 ? 1 : 0}.png`)
        }
        createEffect(() => {
          const n = windowCount()
          badge.label = `${n}`
          badge.visible = n > 0
        })
        const evtId = hyprland.connect("event", refreshOnMove)
        onCleanup(() => hyprland.disconnect(evtId))

        const urgentDot = new Gtk.Label()
        urgentDot.set_css_classes(["urgent"])
        urgentDot.halign = Gtk.Align.START
        urgentDot.valign = Gtk.Align.START
        urgentDot.label = "!"
        overlay.add_overlay(urgentDot)
        createEffect(() => { urgentDot.visible = hasUrgent() })

        btn.set_child(overlay)

        // Right-click → icon picker
        const picker = buildIconPicker(id, btn)
        const gc = new Gtk.GestureClick()
        gc.set_button(3)
        gc.connect("pressed", () => picker.popup())
        btn.add_controller(gc)

        wrap.append(btn)

        // ── Tmp workspace dots ────────────────────────────────────────────
        const dotsBox = new Gtk.Box({
          orientation: Gtk.Orientation.VERTICAL,
          spacing: 6,
          halign: Gtk.Align.CENTER,
        })
        dotsBox.set_css_classes(["tmp-dots"])
        dotsBox.visible = false

        createEffect(() => {
          let child = dotsBox.get_first_child()
          while (child) {
            const next = child.get_next_sibling()
            dotsBox.remove(child)
            child = next
          }

          const ids = subIds()
          const info = activeSub()
          dotsBox.visible = ids.length > 0

          for (const subId of ids) {
            const dot = new Gtk.Box()
            dot.set_size_request(10, 10)
            const isActive = info !== null && info.subId === subId
            dot.set_css_classes(
              isActive ? ["tmp-dot", `tmp-dot-mon-${info!.monId}`] : ["tmp-dot"]
            )
            const gc = new Gtk.GestureClick()
            gc.connect("pressed", () => changeWorkspace(subId))
            dot.add_controller(gc)
            dotsBox.append(dot)
          }
        })

        wrap.append(dotsBox)
      }}
    />
  )
}

export function WorkspacesContainer() {
  return (
    <box class="workspace-element container" orientation={1}>
      {Array.from({ length: WORKSPACES }, (_, i) => Workspace(i + 1))}
    </box>
  )
}
