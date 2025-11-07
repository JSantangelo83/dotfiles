#!/bin/bash
# Import config only once
CONFIG_MARKER="/home/js/.config/dotfiles/ambilight/.hyperion_config_imported"
CONFIG_FILE="/home/js/.config/dotfiles/ambilight/hyperion.config.json"

if [ ! -f "$CONFIG_MARKER" ]; then
    hyperiond --importConfig "$CONFIG_FILE"
    touch "$CONFIG_MARKER"
fi

# Start hyperiond service
systemctl --user start hyperiond.service

# Wait for hyperiond to be ready
while ! nc -z localhost 19444; do sleep 1; done

# Run your Python script and log output
exec /usr/bin/python3 /home/js/.config/dotfiles/ambilight/run.py >> /home/js/.config/dotfiles/ambilight/ambilight.log 2>&1

