const hour = Variable('', { poll: [1000, 'date +%H'] })
const min = Variable('', { poll: [1000, 'date +%M'] })
const date = Variable('', { poll: [60000, 'date "+%A %d %B"'] })

const HourMin = (label:string, hourmin: (typeof hour | typeof min)) => Widget.Box({
    children: [
        Widget.Label({
            vexpand: false,
            className: 'hourmin',
            label: hourmin.bind(),
            justification: 'center',
        }),
        Widget.Box({
            vertical: true,
            valign: 3,
            className: 'label',
            children: [
                Widget.Label({
                    label: label.charAt(0)
                }),
                Widget.Label({
                    label: label.charAt(1)
                })
            ]
        })
    ]
})

export const Clock = Widget.CenterBox({
    className: 'clock-element container',
    centerWidget: Widget.Box({
        hexpand: true,
        vertical: true,
        tooltipText: date.bind(),
        children: [
            HourMin('hs', hour),
            HourMin('mn',min),
        ]
    })
})

