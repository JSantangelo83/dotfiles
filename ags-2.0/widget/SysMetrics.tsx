import { createState, createEffect } from "ags"
import { Gtk } from "ags/gtk4"
import GLib from "gi://GLib"
import { execAsync } from "ags/process"

// Correct: idle is field index 4 in /proc/stat (cpu user nice system IDLE iowait ...)
const CPU_CMD = [
  "bash", "-c",
  "read -ra a <<< $(grep '^cpu ' /proc/stat); sleep 0.3;" +
  "read -ra b <<< $(grep '^cpu ' /proc/stat);" +
  "idle=$((b[4]-a[4])); t=0; for i in 1 2 3 4 5 6 7 8; do t=$((t+b[i]-a[i])); done;" +
  "[ $t -eq 0 ] && echo 0 || echo $(( (t-idle)*100/t ))",
]
const RAM_CMD  = ["bash", "-c", "free | awk '/Mem/{u=$2-$7; printf \"%.0f %.2f\", u/$2*100, u/1048576}'"]
// Sample /proc/diskstats twice 0.5s apart → MB/s total throughput (read+write)
const DISK_CMD = [
  "bash", "-c",
  "dev=$(lsblk -no pkname $(df / | awk 'NR==2{print $1}') 2>/dev/null | head -1);" +
  "s1=$(awk -v d=\"$dev\" '$3==d{print $6+$10; exit}' /proc/diskstats);" +
  "sleep 0.5;" +
  "s2=$(awk -v d=\"$dev\" '$3==d{print $6+$10; exit}' /proc/diskstats);" +
  "awk \"BEGIN{printf \\\"%.1f\\\", ($s2-$s1)/1024}\"",
]

const TOP3: Record<string, string[]> = {
  cpu:  ["bash", "-c", "ps --no-headers -eo comm,pcpu --sort=-pcpu | head -3 | awk '{printf \"%-14s %5.1f%%\\n\", $1, $2}'"],
  mem:  ["bash", "-c", "ps --no-headers -eo comm,pmem,rss --sort=-rss | head -3 | awk '{mb=$3/1024; if(mb>=1024) printf \"%-12s %4.1f%% %5.1fG\\n\",$1,$2,mb/1024; else printf \"%-12s %4.1f%% %4.0fM\\n\",$1,$2,mb}'"],
  disk: [
    "bash", "-c",
    "for f in /proc/[0-9]*/io; do " +
      "name=$(cat \"${f%io}comm\" 2>/dev/null); " +
      "[[ -n $name ]] || continue; " +
      "r=$(awk '/^read_bytes/{print $2}' \"$f\" 2>/dev/null); " +
      "w=$(awk '/^write_bytes/{print $2}' \"$f\" 2>/dev/null); " +
      "printf '%d %s\\n' \"$(( ${r:-0}+${w:-0} ))\" \"$name\"; " +
    "done 2>/dev/null | sort -rn | head -3 | " +
    "awk '{mb=$1/1024/1024; if(mb>=1024) printf \"%-14s %.1fG\\n\",$2,mb/1024; else printf \"%-14s %.0fM\\n\",$2,mb}'",
  ],
}

type Metric = "cpu" | "mem" | "disk"

const METRIC_ICONS: Record<Metric, string> = { cpu: "󰻠", mem: "󰍛", disk: "󰋊" }
const METRIC_LABELS: Record<Metric, string> = { cpu: "Cpu", mem: "Mem", disk: "Disk I/O" }

// Module-level state for the bar icon color, polled in the background
const [metricsIconClass, setMetricsIconClass] = createState("")

function pollMetricsIcon() {
  Promise.all([
    execAsync(CPU_CMD).then(v => parseInt(v) || 0).catch(() => 0),
    execAsync(RAM_CMD).then(v => parseInt(v.split(" ")[0]) || 0).catch(() => 0),
  ]).then(([cpu, mem]) => {
    const avg = (cpu + mem) / 2
    if (avg < 35) setMetricsIconClass("metrics-green")
    else if (avg < 65) setMetricsIconClass("metrics-yellow")
    else setMetricsIconClass("metrics-red")
  }).catch(() => {})
}

pollMetricsIcon()
GLib.timeout_add(GLib.PRIORITY_DEFAULT, 10000, () => {
  pollMetricsIcon()
  return GLib.SOURCE_CONTINUE
})

interface Row { widget: Gtk.Box; update: (value: number, label?: string) => void }

function makeRow(m: Metric, onClick: () => void, maxValue = 100): Row {
  const outer = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 0 })
  outer.set_css_classes(["metric-row"])

  const btn = new Gtk.Button()
  btn.set_css_classes(["metric-btn"])
  btn.hexpand = true

  const inner = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 4 })
  inner.hexpand = true

  const header = new Gtk.Box({ spacing: 6 })
  const icon = new Gtk.Label({ label: METRIC_ICONS[m] })
  icon.set_css_classes(["metric-icon", `metric-icon-${m}`])
  const name = new Gtk.Label({ label: METRIC_LABELS[m], halign: Gtk.Align.START, hexpand: true })
  name.set_css_classes(["metric-name"])
  const val = new Gtk.Label({ label: "–", halign: Gtk.Align.END })
  val.set_css_classes(["metric-value", `metric-value-${m}`])
  header.append(icon)
  header.append(name)
  header.append(val)

  const bar = new Gtk.ProgressBar()
  bar.set_css_classes(["metric-bar", `metric-bar-${m}`])
  bar.hexpand = true

  inner.append(header)
  inner.append(bar)
  btn.set_child(inner)
  btn.connect("clicked", onClick)
  outer.append(btn)

  return {
    widget: outer,
    update: (value, label) => {
      val.label = label ?? `${Math.round(value)}%`
      bar.fraction = Math.min(1, Math.max(0, value / maxValue))
    },
  }
}

function buildPopover(parent: Gtk.Widget): Gtk.Popover {
  const pop = new Gtk.Popover()
  pop.set_parent(parent)
  pop.set_css_classes(["wled-popup"])
  pop.has_arrow = false

  const root = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 0 })
  root.set_css_classes(["metrics-popover"])

  const hdr = new Gtk.Label({ label: "System" })
  hdr.set_css_classes(["wled-title"])
  root.append(hdr)
  root.append(new Gtk.Separator())

  let selected: Metric | null = null

  const procSep = new Gtk.Separator()
  procSep.visible = false

  const procBox = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 2 })
  procBox.set_css_classes(["proc-panel"])
  procBox.visible = false

  const procLabels = [0, 1, 2].map(() => {
    const l = new Gtk.Label({ halign: Gtk.Align.START })
    l.set_css_classes(["proc-row"])
    procBox.append(l)
    return l
  })

  function showProcs(m: Metric) {
    execAsync(TOP3[m]).then(out => {
      const lines = out.trim().split("\n").filter(Boolean)
      procLabels.forEach((l, i) => {
        l.label = lines[i] ? `› ${lines[i]}` : ""
        l.visible = !!lines[i]
      })
      procSep.visible = true
      procBox.visible = true
    }).catch(() => {})
  }

  function toggleMetric(m: Metric) {
    if (selected === m) {
      selected = null
      procSep.visible = false
      procBox.visible = false
    } else {
      selected = m
      showProcs(m)
    }
  }

  const cpuRow  = makeRow("cpu",  () => toggleMetric("cpu"))
  const memRow  = makeRow("mem",  () => toggleMetric("mem"))
  const diskRow = makeRow("disk", () => toggleMetric("disk"), 500)

  const body = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 0 })
  body.set_css_classes(["metrics-body"])
  body.append(cpuRow.widget)
  body.append(memRow.widget)
  body.append(diskRow.widget)
  root.append(body)
  root.append(procSep)
  root.append(procBox)
  pop.set_child(root)

  function fetchAll() {
    execAsync(CPU_CMD).then(v  => cpuRow.update(parseInt(v)  || 0)).catch(() => {})
    execAsync(RAM_CMD).then(v => {
      const [p, g] = v.trim().split(" ")
      const pct = parseInt(p) || 0
      const gb  = parseFloat(g) || 0
      memRow.update(pct, `${pct}% · ${gb >= 1 ? `${gb.toFixed(1)}G` : `${(gb * 1024).toFixed(0)}M`}`)
    }).catch(() => {})
    execAsync(DISK_CMD).then(v => { const mb = parseFloat(v) || 0; diskRow.update(mb, `${mb.toFixed(1)} MB/s`) }).catch(() => {})
    if (selected) showProcs(selected)
  }

  let timer = 0
  pop.connect("notify::visible", () => {
    if (pop.visible) {
      selected = null
      procSep.visible = false
      procBox.visible = false
      fetchAll()
      timer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 3000, () => {
        if (!pop.visible) { timer = 0; return GLib.SOURCE_REMOVE }
        fetchAll()
        return GLib.SOURCE_CONTINUE
      })
    } else {
      if (timer) { GLib.source_remove(timer); timer = 0 }
    }
  })

  return pop
}

export default function SysMetrics() {
  return (
    <button
      class="wled-button flat"
      tooltipText="System"
      $={(btn: Gtk.Button) => {
        const lbl = new Gtk.Label({ label: "󰍛" })
        lbl.set_css_classes(["wled-icon"])
        btn.set_child(lbl)

        createEffect(() => {
          const cls = metricsIconClass()
          lbl.set_css_classes(cls ? ["wled-icon", cls] : ["wled-icon"])
        })

        const pop = buildPopover(btn)
        btn.connect("clicked", () => pop.popup())
      }}
    />
  )
}
