from typing import List  # noqa: F401
import json
import environments
import eventlogger
import os
import subprocess
import time
import sys
import socket
from libqtile import layout, hook
from libqtile.command.client import InteractiveCommandClient
from libqtile.config import Click, Drag, Key, Match
from libqtile.utils import guess_terminal
from libqtile.config import EzKey as Key, Group
from libqtile.lazy import lazy
from libqtile.backend.base import Window
from libqtile import qtile
from libqtile.log_utils import logger

persisted = json.load(open('/home/js/.config/qtile/persisted.json', 'r'))
selectedEnvironment = environments.getEnv(persisted['environment'])()

terminal = guess_terminal()

#@hook.subscribe.startup_once
#def autostart():
#    home = os.path.expanduser('~/.customscripts/startup_once.sh') # path to my script, under my user directory
#    subprocess.call([home])

@hook.subscribe.group_window_add
def group_window_add(group, window):
    # Guardar una referencia al workspace anterior en la ventana
    window._group_from = window.qtile.current_group

    # Actualizar el recuento de ventanas en el grupo actual si no es un grupo temporal
    updateEwwGroup(group.name, windows=str(len(group.windows) + 1))

    # Actualizar el recuento de ventanas en el grupo anterior (si lo hay) y no es un grupo temporal
    group_from = window._group_from
    log(f'group_from: {group_from.name}, windows: {str(len(group_from.windows) + 1)}')
    if group_from != group:
        log('entre aca?')
        updateEwwGroup(group_from.name, windows=str(len(group_from.windows)))

@hook.subscribe.client_killed
def client_killed(window):
    remove_empty_tmp_groups()
    windows = str(len(window.group.windows))
    log(f'group_name: {window.group.name}, windows: {len(window.group.windows)}')
    updateEwwGroup(window.group.name, windows=windows)


@hook.subscribe.client_urgent_hint_changed
def client_urgent_hint_changed(window):
    alert = 'true' if window._demands_attention else 'false'
    updateEwwGroup(window.group.name, alert=alert)

def remove_empty_tmp_groups():
    # Get a list of group names that contain "tmp"
    tmp_groups = [group.name for group in qtile.groups if "tmp" in group.name]

    # Remove the "tmp" groups that have no windows
    if(len(tmp_groups) > 0):
        for group_name in tmp_groups:
            group = qtile.groups_map[group_name]
            if not group.windows:
                qtile.delete_group(group_name)

@hook.subscribe.setgroup
def setgroup():
    #TODO: check if is necessary to check all groups instead of just the current one
    for group in qtile.groups:
        updateEwwGroup(group.name, monitor=group.screen.index if group.screen else '-1')

def getNextTmpGroup(create=False):
        #current workspace number
        parent_ws = qtile.current_screen.group.name[0]
        if not create:
            #if there is any temp workspace for the current group
            if any(group.name.startswith(parent_ws) and 'tmp' in group.name for group in qtile.groups):
                #If the group name lengths 1, that means that is a parent group
                if(len(qtile.current_screen.group.name) == 1):
                    return qtile.current_screen.group.name + 'tmp0'
                else:
                    #current index of the tmp group
                    idx = int(qtile.current_screen.group.name[-1])
                    #If there is a following tmp workspace i go to it
                    if(any(group.name.endswith(str(idx + 1)) and group.name.startswith(parent_ws) and 'tmp' in group.name for group in qtile.groups)):
                        idx = int(qtile.current_screen.group.name[-1]) + 1
                    #If the current workspace is the last one, i go back to the parent one
                    else:
                        idx = -1
                    
                    return parent_ws + 'tmp' + str(idx) if idx > -1 else parent_ws
            return parent_ws
        else:
            #ver si estoy en el parent
            if(len(qtile.current_screen.group.name) == 1):
                #devuelvo el primer temp
                return qtile.current_screen.group.name + 'tmp0'
            #ver si estoy en un temp
            else:
                #veo si el temp actual tiene mas de 1 ventana
                if(len(qtile.current_screen.group.windows) > 1):
                    #devuelvo el proximo temp
                    return parent_ws + 'tmp' + str(int(qtile.current_screen.group.name[-1]) + 1)
                else:
                    #devuelvo el parent
                    return parent_ws
                        
                    
def moveWindowToGroup(window, group):
    if group.name == window.group.name[0]:
        group_to = getNextTmpGroup(True)
        #check if the group exists and create it if not
        if not any(group.name == group_to for group in qtile.groups):
            qtile.add_group(group_to)
        
        window.togroup(group_to)
    else:
        window.togroup(group.name)
    remove_empty_tmp_groups()

def changeGroup(group):
    if group.name == qtile.current_screen.group.name[0]:
        group_to = getNextTmpGroup()
        qtile.groups_map[group_to].cmd_toscreen()
    else:
        qtile.groups_map[group.name].cmd_toscreen()

def log(msg):
    logger.warning('')
    logger.warning('')
    logger.warning('-------------------')
    logger.warning(msg)
    logger.warning('-------------------')
    logger.warning('')
    logger.warning('')

def updateEwwGroup(index, monitor=None, environment=None, alert=None, windows=None):
    if 'tmp' in index:
        return

    pl = ''
    if monitor is not None:
        pl += f"monitor={monitor} "
    if environment is not None:
        pl += f"environment='{environment}' "
    if alert is not None:
        pl += f"alert={alert} "
    if windows is not None:
        pl += f"windows={windows} "

    pl = pl.strip()
    pl += '\n'

    netcat('/tmp/eww-', index, pl)


def netcat(sock_name, id, content):
    # initialize the connection
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(sock_name+id + '.sock')

    sock.sendall(content.encode())
    sock.shutdown(socket .SHUT_WR)
    sock.close()


def openhtop():
    lazy.spawn('htop')
    lazy.spawn('nemo')

keys = [
    # Switch between groups
    Key("M-C-<Right>", lazy.screen.next_group()),
    Key("M-C-<Left>", lazy.screen.prev_group()),

    # Switch between screens
    Key("M-C-y", lazy.next_screen()),

    # Switch between windows
    Key("M-j", lazy.layout.left() if lazy.layout.left_edge() else lambda a:a, desc="Move focus to left"),
    Key("M-l", lazy.layout.right() if lazy.layout.right_edge() else lambda a:a, desc="Move focus to right"),
    Key("M-k", lazy.layout.down() if lazy.layout.down_edge() else lambda a:a, desc="Move focus down"),
    Key("M-i", lazy.layout.up() if lazy.layout.up_edge() else lambda a:a, desc="Move focus up"),


    Key("M-q", lazy.layout.next()),

    # Move Windows
    Key("M-S-j", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key("M-S-l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key("M-S-k", lazy.layout.shuffle_down(), desc="Move window down"),
    Key("M-S-i", lazy.layout.shuffle_up(), desc="Move window up"),

    # Resize Windows
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

    # Columns Layout Specific Keys
    Key("M-S-C-l",
        lazy.layout.swap_column_right().when(layout='columns'),
        lazy.layout.flip().when(layout='monadtall')
        ),
    Key("M-S-C-j",
        lazy.layout.swap_column_left().when(layout='columns'),
        lazy.layout.flip().when(layout='monadtall')
        ),

    Key("M-<Space>", lazy.layout.toggle_split()),


    # Reset Windows size
    Key("M-r", lazy.layout.normalize()),
    # Toggle Floating
    Key("M-d", lazy.window.toggle_floating()),
    # Toggle Minimize
    Key("M-S-m", lazy.window.toggle_minimize()),

    # Toggle bottom bar
    Key("M-f", lazy.hide_show_bar("bottom")),

    # Key("M-<Return>", lazy.spawn(terminal), desc="Launch terminal"),
    Key("M-<Return>", lazy.spawn('kitty'), desc="Launch terminal"),
    # Key("S-M-<Return>", lazy.spawn('/home/js/.config/dotfiles/customscripts/newkitty'), desc="Launch terminal in same directory"),
    Key("M-<Tab>", lazy.next_layout(), desc="Toggle between layouts"),
    Key("M-w", lazy.window.kill(), desc="Kill focused window"),
    Key("M-C-r", lazy.reload_config(), desc="Reload Qtile Config"),
    Key("M-C-S-r", lazy.restart(), desc="Restart Qtile"),
    Key("M-C-q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key("M-e", lazy.spawn("nemo"), desc="Spawn Nemo"),

    # rofi menu
    Key("M-m", lazy.spawn("rofi -show-icons -icon-theme Papirus -show drun")),

    # firefox
    Key("M-b", lazy.spawn("firefox")),
    Key("S-M-b", lazy.spawn("google-chrome-stable")),

    # Screenshot
    Key("M-S-s", lazy.spawn("flameshot gui")),
    # OCR
    Key("M-S-a", lazy.spawn("/home/js/.config/dotfiles/customscripts/ocr-selection")),
    # Env-Selection
    # Key("M-e", lazy.spawn("/home/js/.config/dotfiles/customscripts/env-selector-menu")),

    # Gif
    Key("M-S-r", lazy.spawn("peek")),

    # Color picker
    Key("M-S-c", lazy.spawn("/home/js/.config/dotfiles/customscripts/colorpicker")),
    Key("M-S-C-c", lazy.spawn("/home/js/.config/dotfiles/customscripts/light-control pick")),

    # Next Wallpaper
    Key("M-n", lazy.spawn("/home/js/.config/dotfiles/customscripts/next-wallpaper")),

    # Usb-toggle
    Key("<Pause>", lazy.spawn(
        "/home/js/.config/dotfiles/customscripts/usb-toggle-server/connect audio")),
    Key("<Scroll_Lock>", lazy.spawn(
        "/home/js/.config/dotfiles/customscripts/usb-toggle-server/connect keymouse")),

    # Volume
    Key("<XF86AudioLowerVolume>", lazy.spawn("pamixer --allow-boost --decrease 5")),
    Key("<XF86AudioRaiseVolume>", lazy.spawn("pamixer --allow-boost --increase 5")),
    Key("<XF86AudioMute>", lazy.spawn("pamixer --toggle-mute")),

    # Media control
    Key("<XF86AudioPlay>", lazy.spawn("playerctl play-pause")),
    Key("<XF86AudioNext>", lazy.spawn("playerctl next")),
    Key("<XF86AudioPrev>", lazy.spawn("playerctl previous")),
    Key("<XF86AudioStop>", lazy.spawn("playerctl stop")),

    # Brightness
    Key("<XF86MonBrightnessUp>", lazy.spawn("brightnessctl set +10%")),
    Key("<XF86MonBrightnessDown>", lazy.spawn("brightnessctl set 10%-")),

    # Eww Bar
    Key("M-C-<BackSpace>", lazy.spawn("qtile cmd-obj -o cmd -f hide_show_bar")),
    Key("M-<BackSpace>", lazy.spawn("/home/js/.config/dotfiles/eww/scripts/start")),
    Key("M-S-<BackSpace>", lazy.spawn("/home/js/.config/dotfiles/eww/scripts/stop")),
    Key("M-C-S-<BackSpace>", lazy.spawn("eww inspector")),



]

extraKeys = ['<grave>', '1', '2', '8', '9', '0', '<minus>', '<equal>']
groups = selectedEnvironment.getGroups()

def handle_window_move_keybind(qtile, group):
    moveWindowToGroup(qtile.current_window, group)

def handle_group_change_keybind(qtile, group):
    changeGroup(group)

for i, group in enumerate(groups):
    keys.extend([
        Key('M-' + str(extraKeys[i]), lazy.function(handle_group_change_keybind, group=group)),
        Key('M-S-' + str(extraKeys[i]), lazy.function(handle_window_move_keybind, group=group)),
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
