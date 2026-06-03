import { Gtk } from "ags/gtk4"
import AstalHyprland from "gi://AstalHyprland"

const hyprland = AstalHyprland.get_default()

export default function Head() {
  return (
    <button
      class="head-element container"
      onClicked={() => hyprland.message_async("dispatch overview:toggle", () => {})}
    >
      <image
        file={`${SRC}/assets/arch-icon.png`}
        pixelSize={40}
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
      />
    </button>
  )
}
