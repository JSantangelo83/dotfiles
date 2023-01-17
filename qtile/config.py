from typing import List  # noqa: F401
import json,environments,eventlogger,os,subprocess
from libqtile import layout,hook
from libqtile.config import Click, Drag, Key, Match
from libqtile.utils import guess_terminal
from libqtile.config import EzKey as Key
from libqtile.lazy import lazy

persisted = json.load(open('/home/js/.config/qtile/persisted.json','r'))
selectedEnvironment = environments.getEnv(persisted['environment'])()

terminal = guess_terminal()

def openhtop():
    lazy.spawn('htop')
    lazy.spawn('nemo')

keys = [
    #Switch between groups
    Key("M-C-<Right>", lazy.screen.next_group()),
    Key("M-C-<Left>", lazy.screen.prev_group()),

    #Switch between screens
    Key("M-C-y", lazy.next_screen()),

    # Switch between windows
    Key("M-j", lazy.layout.left(), desc="Move focus to left"),
    Key("M-l", lazy.layout.right(), desc="Move focus to right"),
    Key("M-k", lazy.layout.down(), desc="Move focus down"),
    Key("M-i", lazy.layout.up(), desc="Move focus up"),
    Key("M-q", lazy.window.toggle_fullscreen()),
    
    #Move Windows
    Key("M-S-j", lazy.layout.shuffle_left(),desc="Move window to the left"),
    Key("M-S-l", lazy.layout.shuffle_right(),desc="Move window to the right"),
    Key("M-S-k", lazy.layout.shuffle_down(),desc="Move window down"),
    Key("M-S-i", lazy.layout.shuffle_up(), desc="Move window up"),
    
    #Resize Windows
    Key("M-C-j",
        lazy.layout.shrink_main().when(layout='monadtall'),
        lazy.layout.grow_left().when(layout='columns')
     ),
    
    Key("M-C-l",
        lazy.layout.grow_main().when(layout='monadtall'),
        lazy.layout.grow_right().when(layout='columns')
     ),
    
    Key("M-C-k",
        lazy.layout.shrink().when(layout='monadtall'),
        lazy.layout.grow_down().when(layout='columns')
     ),
    
    Key("M-C-i",
        lazy.layout.grow().when(layout='monadtall'),
        lazy.layout.grow_up().when(layout='columns')
     ),

    #Columns Layout Specific Keys
    Key("M-S-C-l", 
        lazy.layout.swap_column_right().when(layout='columns'),
        lazy.layout.flip().when(layout='monadtall')
    ),
    Key("M-S-C-j", 
        lazy.layout.swap_column_left().when(layout='columns'),
        lazy.layout.flip().when(layout='monadtall')
    ),
    
    Key("M-<Space>", lazy.layout.toggle_split()),
    

    #Reset Windows size
    Key("M-r", lazy.layout.normalize()),
    #Toggle Floating
    Key("M-d", lazy.window.toggle_floating()),
    #Toggle Minimize
    Key("M-S-m", lazy.window.toggle_minimize()),

    #Toggle bottom bar
    Key("M-f",lazy.hide_show_bar("bottom")),
	
    # Key("M-<Return>", lazy.spawn(terminal), desc="Launch terminal"),
    Key("M-<Return>", lazy.spawn('kitty'), desc="Launch terminal"),
    # Key("S-M-<Return>", lazy.spawn('/home/js/.config/dotfiles/customscripts/newkitty'), desc="Launch terminal in same directory"),
    Key("M-<Tab>", lazy.next_layout(), desc="Toggle between layouts"),
    Key("M-w", lazy.window.kill(), desc="Kill focused window"),
    Key("M-C-r", lazy.reload_config(), desc="Reload Qtile Config"),
    Key("M-C-S-r", lazy.restart(), desc="Restart Qtile"),    
    Key("M-C-q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key("M-e",lazy.spawn("nemo"),desc="Spawn Nemo"),
            
    #rofi menu
    Key("M-m", lazy.spawn("rofi -show-icons -icon-theme Papirus -show drun")),

    #firefox
    Key("M-b", lazy.spawn("firefox")),
    Key("S-M-b", lazy.spawn("google-chrome-stable")),

    #Screenshot
    Key("M-S-s", lazy.spawn("flameshot gui")),
    #OCR
    Key("M-S-a", lazy.spawn("/home/js/.config/dotfiles/customscripts/ocr-selection")),
    #Env-Selection
    # Key("M-e", lazy.spawn("/home/js/.config/dotfiles/customscripts/env-selector-menu")),

    #Gif
    Key("M-S-r", lazy.spawn("peek")),

    #Color picker
    Key("M-S-c", lazy.spawn("/home/js/.config/dotfiles/customscripts/colorpicker")),
    
    #Next Wallpaper
    Key("M-n",lazy.spawn("/home/js/.config/dotfiles/customscripts/next-wallpaper")),

    #Usb-toggle
    Key("<Pause>",lazy.spawn("/home/js/.config/dotfiles/customscripts/usb-toggle-server/connect audio")),
    Key("<Scroll_Lock>",lazy.spawn("/home/js/.config/dotfiles/customscripts/usb-toggle-server/connect keymouse")),
    
    # Volume
    Key("<XF86AudioLowerVolume>", lazy.spawn("pamixer --decrease 5")),
    Key("<XF86AudioRaiseVolume>", lazy.spawn("pamixer --increase 5")),
    Key("<XF86AudioMute>", lazy.spawn("pamixer --toggle-mute")),

    # Media control
    Key("<XF86AudioPlay>", lazy.spawn("playerctl play-pause")),
    Key("<XF86AudioNext>", lazy.spawn("playerctl next")),
    Key("<XF86AudioPrev>", lazy.spawn("playerctl previous")),
    Key("<XF86AudioStop>", lazy.spawn("playerctl stop")),

    #Brightness
    Key("<XF86MonBrightnessUp>", lazy.spawn("brightnessctl set +10%")),
    Key("<XF86MonBrightnessDown>", lazy.spawn("brightnessctl set 10%-")),

    #Eww Bar
    Key("M-C-<BackSpace>", lazy.spawn("qtile cmd-obj -o cmd -f hide_show_bar")),
    Key("M-<BackSpace>", lazy.spawn("/home/js/.config/dotfiles/eww/scripts/start")),
    Key("M-S-<BackSpace>", lazy.spawn("/home/js/.config/dotfiles/eww/scripts/stop")),

        
]

extraKeys = ['<grave>','1','2','8','9','0','<minus>','<equal>']
groups = selectedEnvironment.getGroups()
    
for i, group in enumerate(groups):
        keys.extend([
            Key('M-'+ str(extraKeys[i]), lazy.group[group.name].toscreen()),
            Key('M-S-'+ str(extraKeys[i]), lazy.window.togroup(group.name)),
        ])

layouts = selectedEnvironment.getLayouts()

widget_defaults = dict(
    font='UbuntuMono Nerd Font',
    fontsize=16,
    padding=5,
)
extension_defaults = widget_defaults.copy()

screens = selectedEnvironment.getScreens()

# Drag floating layouts.
mouse = [
    Drag(["mod4"], "Button1", lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    Drag(["mod4"], "Button3", lazy.window.set_size_floating(),
         start=lazy.window.get_size()),
    Click(["mod4"], "Button2", lazy.window.bring_to_front())
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: List
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(
            border_width=0,
            float_rules=[
                # Run the utility of `xprop` to see the wm class and name of an X client.
                *layout.Floating.default_float_rules,
                Match(wm_class='confirmreset'),  # gitk
                Match(wm_class='makebranch'),  # gitk
                Match(wm_class='maketag'),  # gitk
                Match(wm_class='ssh-askpass'),  # ssh-askpass
                Match(title='branchdialog'),  # gitk
                Match(title='pinentry'),  # GPG key password entry
            ])
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"

# def changeEnv(name):
    # with open('/home/js/.config/qtile/persisted.json','w') as f:
        # if name == 'Hacking':
            # persisted['environment'] = 'Hacking'
            # json.dump(persisted, f)
            # lazy.reload_config()
        # if name == 'Develop':
            # persisted['environment'] = 'Develop'
            # json.dump(persisted, f)
            # lazy.reload_config()

