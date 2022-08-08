from libqtile import bar, layout, widget
from libqtile.config import Group, Screen
import owm,json
import sys, inspect

# General widgets
def verticalLine():
    return widget.TextBox(text="")


def smallSpacer():
    return widget.TextBox(text=" ", fontsize=1)


class Default:
    def getLayouts(self):
        return [
            layout.Max(
                margin=10,
            )
        ] + self.customLayouts()

    def getGroups(self):
        return self.customGroups()

    def getScreens(self):
        return [
            Screen(
                top=bar.Bar(
                    self.customScreens()[0]["top"]["widgets"]
                    + [
                        widget.WidgetBox(
                            widgets=[
                                widget.Systray(
                                    icon_size=16,
                                    padding=10,
                                ),
                                smallSpacer(),
                            ],
                            text_closed="",
                            text_open="",
                            close_button_location="right",
                        ),
                        smallSpacer(),
                        owm.OpenWeatherMap(
                            api_key="7834197c2338888258f8cb94ae14ef49",
                            latitude=-34.6497,
                            longitude=-58.3834,
                            foreground="#88E7E7",
                            format="{icon} {temp:.1f}{temp_units}",
                        ),
                        verticalLine(),
                        widget.CPU(
                            foreground="#FC88F8",
                            format="﬙  {load_percent}%",
                        ),
                        verticalLine(),
                        widget.Memory(
                            foreground="#A8F0AE",
                            format="{MemPercent}%  ﳚ",
                        ),
                        verticalLine(),
                        widget.Clock(format="  %H:%M %d/%m", foreground="#FFF799"),
                        smallSpacer(),
                    ],
                    self.customScreens()[0]["top"]["size"] if "size" in self.customScreens()[0]["top"] else 24,
                    margin=self.customScreens()[0]["top"]["margin"] if "margin" in self.customScreens()[0]["top"] else 1,
                    background=self.customScreens()[0]["top"]["background"] if "background" in self.customScreens()[0]["top"] else "#282C34",
                ),
                **{
                    arg: bar.Bar(
                        self.customScreens()[0][arg]["widgets"],
                        self.customScreens()[0][arg]["size"],
                        **{k: self.customScreens()[0][arg][k] for k in self.customScreens()[0][arg] if k != "size" and k != "widgets"}
                    )
                    for arg in self.customScreens()[0]
                    if arg != "top"
                }
            )
        ] + [
            Screen(**{arg: bar.Bar(args[arg]["widgets"], args[arg]["size"], **{k: args[arg][k] for k in args[arg] if k != "size" and k != "widgets"}) for arg in args})
            for args in self.customScreens()[1:]
        ]

    def customLayouts(self):
        return []

    def customGroups(self):
        return [Group(i) for i in ["1", "2", "3", "4", "5", "6", "7", "8"]]

    def customScreens(self):
        return [
            {
                "top": {
                    "widgets": [
                        widget.GroupBox(
                            fontsize=16,
                            background="#282C34",
                            markup=False,
                            padding=8,
                            center_aligned=True,
                            disable_drag=True,
                            other_current_screen_border="#E15133",
                            use_mouse_wheel=False,
                            highlight_method="line",
                            highlight_color="#FE9001",
                            borderwidth=2,
                        ),
                        widget.Spacer(),
                    ]
                }
            }
        ]
    def getIcon():
        return ''


# Custom Envs
class Code(Default):
    def getIcon():
        return ''
        
    def customGroups(self):
        return [Group(i) for i in [" ", " ", " ", " ", " ", " ", " ", " "]]

    def customLayouts(self):
        return [
            layout.MonadTall(
                margin=10,
                border_width=0,
                border_focus="#E8C7DE",
                single_margin=10,
                single_border_width=0,
                corner_radius=16,
            )
        ]

    def customScreens(self):
        return [
            {
                "top": {
                    "widgets": [
                        widget.GroupBox(
                            fontsize=16,
                            background="#282C34",
                            markup=False,
                            padding=8,
                            center_aligned=True,
                            disable_drag=True,
                            other_current_screen_border="#E15133",
                            use_mouse_wheel=False,
                            highlight_method="line",
                            highlight_color="#FE9001",
                            borderwidth=2,
                        ),
                        verticalLine(),
                        widget.TaskList(
                            txt_floating="",
                            txt_minimized="",
                            background="#383C44",
                            fontsize=10,
                            spacing=-5,
                            icon_size=16,
                            margin=5,
                            txt_maximized="",
                            padding=3,
                            border=None,
                            parse_text=lambda t: "",
                            foreground="#FE9001",
                        ),
                        smallSpacer(),
                        smallSpacer(),
                        smallSpacer(),
                        smallSpacer(),
                        smallSpacer(),
                        smallSpacer(),
                        smallSpacer(),
                        smallSpacer(),
                        widget.CryptoTicker(
                            crypto="BTC",
                            format="{symbol}{amount:.2f} ﴑ",
                        ),
                        smallSpacer(),
                        widget.CryptoTicker(
                            crypto="ETH",
                            format="{symbol}{amount:.2f} ﲹ",
                        ),
                        widget.Spacer(),
                    ],
                },
            },
        ]


def getEnv(selected):
    for name, obj in inspect.getmembers(sys.modules[__name__]):
        if inspect.isclass(obj):
            if name == selected:
                return obj
    return Default

def getEnvList(): return [[name,obj.getIcon()] for name,obj in inspect.getmembers(sys.modules[__name__], lambda member: inspect.isclass(member) and member.__module__ == __name__)]
def getCurrentEnv(): return json.load(open('/home/js/.config/qtile/persisted.json','r'))['environment']
#Scripting version
# if len(sys.argv) > 1:
    # if sys.argv[1] == 'get':
        # for name,obj in inspect.getmembers(sys.modules[__name__], lambda member: inspect.isclass(member) and member.__module__ == __name__):
            # print(name)
        
