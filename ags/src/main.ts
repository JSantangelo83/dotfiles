import { TotalBar } from "./components/TotalBar";
import { HPercentage } from "./utils/screen";

const BarWindow = (monitor: number) => Widget.Window({
    margins: [HPercentage(1), HPercentage(1.5)],
    monitor,
    name: `bar${monitor}`,
    css: 'background-color: transparent;',
    anchor: ["top", "left"],
    child: TotalBar,
})


const targetCss = `/tmp/ags-style.css`

await Utils.exec(`sassc ${App.configDir}/src/style.scss ${targetCss}`)
await Utils.exec(`bash ${App.configDir}/scripts/setup-icons.sh`)

App.addIcons(`/home/js/.cache/ags-bar/assets`)

App.config({
    windows: [BarWindow(0)],
    style: targetCss,
})