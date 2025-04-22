import { HPercentage } from "../utils/screen"
import { BarContainer } from "./Bar"
import { Head } from "./Head"

export const TotalBar = Widget.Box({
    vertical: true,
    spacing: HPercentage(1.3),
    children: [
        Head,
        BarContainer
    ],
})