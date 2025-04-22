import { getTimeLabel } from "../utils/helper";

const battery = await Service.import('battery')

const tooltip = Utils.merge([
    battery.bind('percent'),
    battery.bind('time_remaining'),
    battery.bind('charging')
], (percent: number, timeRemaining: number, charging: boolean) => {
    // Battery alert
    if (percent < 15 && !charging) {
        Utils.exec(['notify-send', 'Low battery', `${percent}% remaining`, '--urgency', 'critical','--expire-time','10000'])
    }

    // Battery tooltip
    return `${percent}% (${getTimeLabel(timeRemaining)}${charging ? 'to full charge' : 'remaining'})`
})

export const Battery = Widget.CenterBox({
    tooltipText: tooltip,
    centerWidget: Widget.Icon({
        icon: battery.bind('icon_name'),
        visible: battery.bind('available'),
        size: 36,
    })
})
