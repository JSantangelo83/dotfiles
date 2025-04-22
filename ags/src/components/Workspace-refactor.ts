import { WORKSPACES } from "../utils/consts";

const hyprland = await Service.import('hyprland')

export const Workspace = (id: number) => {
    return Widget.EventBox({})
}

export const WorkspacesContainer = Widget.Box({
    className: 'workspace-element container',
    vertical: true,
    children: Array.from({ length: WORKSPACES }, (_, i) => Workspace(i + 1)),
})