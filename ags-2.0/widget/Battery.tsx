import { createBinding, createComputed, createEffect } from "ags"
import { execAsync } from "ags/process"
import AstalBattery from "gi://AstalBattery"

const device = AstalBattery.Device.get_default()

function getTimeLabel(seconds: number): string {
  if (seconds < 0) return ""
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  let time = ""
  if (hours > 0) time += `${hours}h `
  if (minutes > 0) time += `${minutes}m `
  return time
}

export default function Battery() {
  if (!device) return <box />

  const percentage  = createBinding(device, "percentage")
  const charging    = createBinding(device, "charging")
  const iconName    = createBinding(device, "icon-name")
  const isPresent   = createBinding(device, "is-present")
  const timeToEmpty = createBinding(device, "time-to-empty")
  const timeToFull  = createBinding(device, "time-to-full")

  const tooltip = createComputed(() => {
    const p = Math.round(percentage() * 100)
    const c = charging()
    const t = c ? timeToFull() : timeToEmpty()
    return `${p}% (${getTimeLabel(t)}${c ? "to full charge" : "remaining"})`
  })

  createEffect(() => {
    const p = percentage()
    if (isPresent() && p > 0 && p < 0.15 && !charging()) {
      execAsync(["notify-send", "Low battery", `${Math.round(p * 100)}% remaining`, "--urgency", "critical", "--expire-time", "10000"])
        .catch(console.error)
    }
  })

  return (
    <centerbox class="battery-element" tooltipText={tooltip}>
      <box />
      <image iconName={iconName} visible={isPresent} pixelSize={36} />
      <box />
    </centerbox>
  )
}
