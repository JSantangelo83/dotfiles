import { onCleanup } from "ags"
import { Gtk } from "ags/gtk4"
import AstalTray from "gi://AstalTray"

const tray = AstalTray.get_default()

function makeTrayItem(item: AstalTray.TrayItem): Gtk.Box {
  const box = new Gtk.Box()
  box.set_css_classes(["tray-item"])
  box.set_halign(Gtk.Align.CENTER)

  const img = new Gtk.Image()
  img.set_pixel_size(24)
  img.set_from_gicon(item.gicon)
  box.append(img)

  const changedId = item.connect("changed", () => img.set_from_gicon(item.gicon))
  box.connect("destroy", () => item.disconnect(changedId))

  const leftClick = new Gtk.GestureClick()
  leftClick.set_button(1)
  leftClick.connect("released", () => item.activate(0, 0))
  box.add_controller(leftClick)

  const menuModel = item.get_menu_model()
  if (menuModel) {
    const actionGroup = item.get_action_group()
    if (actionGroup) box.insert_action_group("dbusmenu", actionGroup)

    const popover = Gtk.PopoverMenu.new_from_model(menuModel)
    popover.set_parent(box)

    const rightClick = new Gtk.GestureClick()
    rightClick.set_button(3)
    rightClick.connect("pressed", () => {
      item.about_to_show()
      popover.popup()
    })
    box.add_controller(rightClick)
  }

  return box
}

export default function Tray() {
  return (
    <box
      class="tray-element"
      orientation={1}
      spacing={14}
      halign={Gtk.Align.CENTER}
      $={(b: Gtk.Box) => {
        b.visible = false
        const widgets = new Map<string, Gtk.Box>()

        for (const item of tray.get_items()) {
          const w = makeTrayItem(item)
          widgets.set(item.item_id, w)
          b.append(w)
        }
        b.visible = widgets.size > 0

        const addedId = tray.connect("item-added", (_: AstalTray.Tray, itemId: string) => {
          if (widgets.has(itemId)) return
          const item = tray.get_item(itemId)
          if (!item) return
          const w = makeTrayItem(item)
          widgets.set(itemId, w)
          b.append(w)
          b.visible = true
        })

        const removedId = tray.connect("item-removed", (_: AstalTray.Tray, itemId: string) => {
          const w = widgets.get(itemId)
          if (!w) return
          b.remove(w)
          widgets.delete(itemId)
          b.visible = widgets.size > 0
        })

        onCleanup(() => {
          tray.disconnect(addedId)
          tray.disconnect(removedId)
        })
      }}
    />
  )
}
