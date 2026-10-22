import { readFile, monitorFile } from "ags/file"
import { Gtk } from "ags/gtk4"
import Gdk from "gi://Gdk"

const CONFIG_PATH = `${SRC}/jsbar.jsonc`

export interface BarConfig {
  // Colors
  bg: string
  bgDark: string
  bgDarkHover: string
  fg: string
  fgDark: string
  fg2: string
  selected: string
  disabled: string
  danger: string
  warning: string
  success: string
  accents: string[]
  metricCpu: string
  metricMem: string
  metricDisk: string
  ambilightColor: string
  borderRadius: string
  borderRadius2: string
  padding: string

  // Bar / window
  monitor: string
  barMarginsPercent: number
  barGap: number

  // Widgets
  widgets: {
    workspaces: boolean
    sysmetrics: boolean
    tray: boolean
    clock: boolean
    wled: boolean
    battery: boolean
  }

  // Workspaces
  workspacesCount: number
  workspaceIconSize: number
  workspaceIconsDir: string

  // WLED
  wledIp: string
  wledSegments: number[]
  wledGamma: number

  // System metrics
  metricsBarPollMs: number
  metricsPopupRefreshMs: number
  metricsThresholdWarn: number
  metricsThresholdCrit: number
  metricsDiskMaxMb: number

  // Audio
  audioMaxVolume: number
  audioPollMs: number

  // Battery
  batteryLowThreshold: number
  batteryNotifyExpireMs: number
}

const DEFAULTS: BarConfig = {
  // Colors
  bg: "#353535",
  bgDark: "#202020",
  bgDarkHover: "#2d2d2d",
  fg: "#A8B0CD",
  fgDark: "#4C536A",
  fg2: "#FFFFFF",
  selected: "rgba(168, 166, 166, 0.1)",
  disabled: "#6A6A6A",
  danger: "#DC3545",
  warning: "#FFFFFF",
  success: "#61D97C",
  accents: ["#673434", "#6E6E2C", "#304079", "#50885B"],
  metricCpu: "#e06060",
  metricMem: "#6090e0",
  metricDisk: "#60c080",
  ambilightColor: "#E8A838",
  borderRadius: "20px",
  borderRadius2: "23px",
  padding: "15px",

  // Bar / window
  monitor: "DP-1",
  barMarginsPercent: 1,
  barGap: 10,

  // Widgets
  widgets: {
    workspaces: true,
    sysmetrics: true,
    tray: true,
    clock: true,
    wled: true,
    battery: true,
  },

  // Workspaces
  workspacesCount: 8,
  workspaceIconSize: 20,
  workspaceIconsDir: "/home/js/.config/dotfiles/eww/assets/workspaces",

  // WLED
  wledIp: "192.168.1.52",
  wledSegments: [0, 1],
  wledGamma: 2.2,

  // Metrics
  metricsBarPollMs: 10000,
  metricsPopupRefreshMs: 3000,
  metricsThresholdWarn: 35,
  metricsThresholdCrit: 65,
  metricsDiskMaxMb: 500,

  // Audio
  audioMaxVolume: 1.5,
  audioPollMs: 3000,

  // Battery
  batteryLowThreshold: 0.15,
  batteryNotifyExpireMs: 10000,
}

function stripJsonc(s: string): string {
  return s
    .replace(/\/\/[^\n]*/g, "")
    .replace(/\/\*[\s\S]*?\*\//g, "")
}

let current: BarConfig = { ...DEFAULTS, widgets: { ...DEFAULTS.widgets } }

function loadConfig() {
  try {
    const raw = readFile(CONFIG_PATH)
    const p   = JSON.parse(stripJsonc(raw))
    const w   = p.widgets ?? {}
    current = {
      // Colors
      bg:             p.bg                   ?? DEFAULTS.bg,
      bgDark:         p["bg-dark"]           ?? DEFAULTS.bgDark,
      bgDarkHover:    p["bg-dark-hover"]     ?? DEFAULTS.bgDarkHover,
      fg:             p.foreground           ?? DEFAULTS.fg,
      fgDark:         p["foreground-dark"]   ?? DEFAULTS.fgDark,
      fg2:            p["foreground-2"]      ?? DEFAULTS.fg2,
      selected:       p.selected             ?? DEFAULTS.selected,
      disabled:       p.disabled             ?? DEFAULTS.disabled,
      danger:         p.danger               ?? DEFAULTS.danger,
      warning:        p.warning              ?? DEFAULTS.warning,
      success:        p.success              ?? DEFAULTS.success,
      accents:        p.accents              ?? DEFAULTS.accents,
      metricCpu:      p["metric-cpu"]        ?? DEFAULTS.metricCpu,
      metricMem:      p["metric-mem"]        ?? DEFAULTS.metricMem,
      metricDisk:     p["metric-disk"]       ?? DEFAULTS.metricDisk,
      ambilightColor: p["ambilight-color"]   ?? DEFAULTS.ambilightColor,
      borderRadius:   p["border-radius"]     ?? DEFAULTS.borderRadius,
      borderRadius2:  p["border-radius-2"]   ?? DEFAULTS.borderRadius2,
      padding:        p.padding              ?? DEFAULTS.padding,
      // Bar / window
      monitor:           p.monitor                ?? DEFAULTS.monitor,
      barMarginsPercent: p["bar-margins-percent"]  ?? DEFAULTS.barMarginsPercent,
      barGap:            p["bar-gap"]              ?? DEFAULTS.barGap,
      // Widgets
      widgets: {
        workspaces: w.workspaces ?? DEFAULTS.widgets.workspaces,
        sysmetrics: w.sysmetrics ?? DEFAULTS.widgets.sysmetrics,
        tray:       w.tray       ?? DEFAULTS.widgets.tray,
        clock:      w.clock      ?? DEFAULTS.widgets.clock,
        wled:       w.wled       ?? DEFAULTS.widgets.wled,
        battery:    w.battery    ?? DEFAULTS.widgets.battery,
      },
      // Workspaces
      workspacesCount:   p["workspaces-count"]    ?? DEFAULTS.workspacesCount,
      workspaceIconSize: p["workspace-icon-size"] ?? DEFAULTS.workspaceIconSize,
      workspaceIconsDir: p["workspace-icons-dir"] ?? DEFAULTS.workspaceIconsDir,
      // WLED
      wledIp:       p["wled-ip"]       ?? DEFAULTS.wledIp,
      wledSegments: p["wled-segments"] ?? DEFAULTS.wledSegments,
      wledGamma:    p["wled-gamma"]    ?? DEFAULTS.wledGamma,
      // Metrics
      metricsBarPollMs:      p["metrics-bar-poll-ms"]      ?? DEFAULTS.metricsBarPollMs,
      metricsPopupRefreshMs: p["metrics-popup-refresh-ms"] ?? DEFAULTS.metricsPopupRefreshMs,
      metricsThresholdWarn:  p["metrics-threshold-warn"]   ?? DEFAULTS.metricsThresholdWarn,
      metricsThresholdCrit:  p["metrics-threshold-crit"]   ?? DEFAULTS.metricsThresholdCrit,
      metricsDiskMaxMb:      p["metrics-disk-max-mb"]      ?? DEFAULTS.metricsDiskMaxMb,
      // Audio
      audioMaxVolume: p["audio-max-volume"] ?? DEFAULTS.audioMaxVolume,
      audioPollMs:    p["audio-poll-ms"]    ?? DEFAULTS.audioPollMs,
      // Battery
      batteryLowThreshold:   p["battery-low-threshold"]    ?? DEFAULTS.batteryLowThreshold,
      batteryNotifyExpireMs: p["battery-notify-expire-ms"] ?? DEFAULTS.batteryNotifyExpireMs,
    }
  } catch {
      current = { ...DEFAULTS, widgets: { ...DEFAULTS.widgets } }
  }
}

// Load at module evaluation so all widgets get correct values at import time.
// Colors hot-reload via the CSS provider; functional values require ags restart.
loadConfig()

export function getConfig(): BarConfig { return current }

function buildCss(): string {
  const t = current
  const a = (i: number) => t.accents[i] ?? DEFAULTS.accents[i]
  return `
window {
  --bar-bg: ${t.bg};
  --bar-bg-dark: ${t.bgDark};
  --bar-bg-dark-hover: ${t.bgDarkHover};
  --bar-fg: ${t.fg};
  --bar-fg-dark: ${t.fgDark};
  --bar-fg-2: ${t.fg2};
  --bar-selected: ${t.selected};
  --bar-disabled: ${t.disabled};
  --bar-danger: ${t.danger};
  --bar-warning: ${t.warning};
  --bar-success: ${t.success};
  --bar-accent-0: ${a(0)};
  --bar-accent-1: ${a(1)};
  --bar-accent-2: ${a(2)};
  --bar-accent-3: ${a(3)};
  --bar-metric-cpu: ${t.metricCpu};
  --bar-metric-mem: ${t.metricMem};
  --bar-metric-disk: ${t.metricDisk};
  --bar-ambilight: ${t.ambilightColor};
  --bar-radius: ${t.borderRadius};
  --bar-radius-2: ${t.borderRadius2};
  --bar-padding: ${t.padding};
}
`
}

export function initTheme() {
  const provider = new Gtk.CssProvider()
  provider.load_from_string(buildCss())

  const display = Gdk.Display.get_default()
  if (display) {
    Gtk.StyleContext.add_provider_for_display(
      display,
      provider,
      Gtk.STYLE_PROVIDER_PRIORITY_USER + 1,
    )
  }

  monitorFile(CONFIG_PATH, () => {
    loadConfig()
    provider.load_from_string(buildCss())
  })
}
