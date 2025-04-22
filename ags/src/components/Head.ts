import { HPercentage, WPercentage } from "../utils/screen";

const hyprland = await Service.import('hyprland')

export const Head = Widget.EventBox({
    // Events
    onPrimaryClick: () => hyprland.messageAsync('dispatch overview:toggle'),
    onHover: self => self.cursor = 'pointer',
    
    // Content
    child: Widget.CenterBox({
        width_request: WPercentage(7 * 0.5625),  // 16:9 ratio
        height_request: HPercentage(7),
        class_name: 'head-element container',
        centerWidget: Widget.Icon({
            icon: `${App.configDir}/assets/arch-icon.png`,
            size: 45,
        }),
    })
});