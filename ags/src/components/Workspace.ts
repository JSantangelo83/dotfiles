import config from '../services/settings';
import { HPercentage, WPercentage } from "../utils/screen";
import { ICON_SIZE, WORKSPACES } from "../utils/consts";

const hyprland = await Service.import('hyprland')

const getMonitorByWorkspace = (/** @type {number} **/ id) => {
    const monitor = hyprland.monitors.find(monitor => monitor.activeWorkspace?.id === id)?.id;
    return monitor !== undefined ? monitor : 'none';
}

const changeWorkspace = (/** @type {number} **/ id) => { hyprland.messageAsync(`dispatch workspace ${id}`) }

export const Workspace = (
    /** @type {number} **/ id,
    // /** @type {number} **/ windows,
) => {
    /** @type {any} */
    return Widget.EventBox({
        onPrimaryClick: _self => changeWorkspace(id),
        child: Widget.Box({
            hexpand: true,
            className: 'item',
            setup: self => self.hook(hyprland, () => {
                // TODO: filter only the event that i need
                self.class_name = `item monitor-${getMonitorByWorkspace(id)}`;
            }),
            children: [Widget.Fixed({
                setup: self => {
                    const ws_settings = config.getWorkspace(id);

                    // Icon of the workspace
                    self.put(
                        Widget.Icon({
                            halign: 3,
                            className: 'icon',
                            size: ICON_SIZE
                        }).hook(hyprland, (self, eName) => {
                            if (self.icon && !['openwindow', 'closewindow', 'movewindow'].includes(eName)) return

                            const ws = hyprland.workspaces.find(workspace => workspace.id === id);
                            const windows = ws?.windows || 0;
                            const icon = ws_settings?.icon || 'workspace-symbolic';

                            const variant = windows > 0 ? 'active' : 'inactive';
                            const iconPath = `${config.current.cache_dir}/assets/${icon}-${variant}.svg`;

                            self.icon = iconPath;

                        }, 'event'),
                        WPercentage(2.3) / 2 - ICON_SIZE / 2, 0
                    );

                    // Label for Windows number
                    self.put(Widget.Label({
                        className: 'label',
                    }).hook(hyprland, (self, eName) => {
                        if (self.label !== '' && !['openwindow', 'closewindow', 'movewindow'].includes(eName)) return

                        const ws = hyprland.workspaces.find(workspace => workspace.id === id);
                        const windows = ws?.windows || 0;

                        self.visible = windows > 0;
                        self.label = `${windows}`;

                    }, 'event'), WPercentage(2.3) / 2 + ICON_SIZE / 2 + 2, HPercentage(1.2));

                    // Danger icon if urgent windows
                    self.put(Widget.Icon({
                        halign: 3,
                        icon: `${config.current.cache_dir}/assets/danger.svg`,
                        size: 10,
                        attribute: {
                            urgentWindows: [],
                        },
                    }).hook(hyprland, (self, windowaddress) => {
                        if (hyprland.getClient(windowaddress)?.workspace?.id == id) {
                            // @ts-ignore
                            self.attribute.urgentWindows.push(windowaddress);
                            self.visible = true;
                        } else {
                            self.visible = false;
                        }
                    }, 'urgent-window').hook(hyprland, (self, eName, windowaddress) => {
                        if (eName !== 'activewindowv2') return

                        if (hyprland.getClient(windowaddress)?.workspace?.id == id) {
                            // @ts-ignore
                            self.attribute.urgentWindows = self.attribute.urgentWindows.filter(w => w !== windowaddress);
                            // @ts-ignore
                            if (self.attribute.urgentWindows.length == 0) self.visible = false;
                        }
                        self.visible = false;
                    }, 'event'),
                        WPercentage(0.5), HPercentage(1.2)
                    );
                }
            })]
        }),
    });
}

export const WorkspacesContainer = Widget.Box({
    className: 'workspace-element container',
    vertical: true,
    children: Array.from({ length: WORKSPACES }, (_, i) => Workspace(i + 1)),
})