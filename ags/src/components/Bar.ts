import { SEPARATION } from "../utils/consts";
import { HPercentage, WPercentage } from "../utils/screen";
import { Battery } from "./Battery";
import { Clock } from "./Clock";
import { WorkspacesContainer } from "./Workspace";

export const BAR_H = HPercentage(89)
export const BAR_W = WPercentage(2.3)

export const StartWidgets = Widget.Box({
    vertical: true,
    children: [
        WorkspacesContainer
    ]
})

export const CenterWidgets = Widget.Box({
    vertical: true,
    children: [
    ]
})

export const EndWidgets = Widget.Box({
    vertical: true,
    spacing: SEPARATION,
    valign: 2,
    children: [
        Clock,
        Battery
    ]
})

const Bar = Widget.CenterBox({
    className: 'bar',
    vertical: true,
    widthRequest: BAR_W,
    spacing: SEPARATION,
    startWidget: StartWidgets,
    centerWidget: CenterWidgets,
    endWidget: EndWidgets
})

export const BarContainer = Widget.CenterBox({
    className: 'bar-element container',
    heightRequest: BAR_H,
    centerWidget: Bar
})