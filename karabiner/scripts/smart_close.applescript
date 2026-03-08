tell application "System Events"
    set frontApp to name of first application process whose frontmost is true
end tell

tell application frontApp
    try
        set visibleWindows to every window whose visible is true
        if (count of visibleWindows) > 1 then
            close front window
        else
            quit
        end if
    on error
        tell application "System Events" to keystroke "w" using command down
    end try
end tell
