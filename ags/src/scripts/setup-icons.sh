settings="$(cat /home/js/.config/ags/default-settings.json)"

if [ -f '/home/js/.config/ags/settings.json' ]; then
  settings="$(cat /home/js/.config/ags/settings.json)"
fi


if [ -z "$settings" ]; then
  echo "No settings.json found"
  exit 1
fi

function cache_icon {
    local icon_file=$1
    local color=$2
    local cached_icon_file=$3
    
    bootstrap_icon_content=$(cat $icon_file)
    cached_icon_content=$(sed "s/fill=\"currentColor\"/fill=\"${color}\"/g" <<< "$bootstrap_icon_content")
    echo "$cached_icon_content" > "$cached_icon_file"
}

CACHE_ROUTE="$(jq -r '.cache_dir' <<< $settings)"
mkdir -p $CACHE_ROUTE/assets

# For every icon
for name in $(jq -r '.icons | keys | .[]' <<< $settings); do
    icon_config=$(jq -r ".icons[\"$name\"]" <<< $settings);
    if [ -z "$icon_config" ]; then
        continue;
    fi
    icon=$(jq -r '.icon' <<< $icon_config);

    if [ -z "$icon" ]; then
        echo "No icon found for workspace $name, skipping"
        continue;
    fi
    color=$(jq -r '.color' <<< $icon_config);
    
    if [ -z "$color" ]; then
        echo "No color found for icon $name, skipping"
        continue;
    fi

    cached_icon_file="$CACHE_ROUTE/assets/$name.svg"
    #  If the icon is already cached, skip
    if [ -f "$cached_icon_file" ]; then
        continue;
    fi

    bootstrap_icon_file="/home/js/.config/ags/assets/bootstrap-icons/$icon.svg"

    # If the icon exists
    if [ -f "$bootstrap_icon_file" ]; then
        cache_icon "$bootstrap_icon_file" "$color" "$cached_icon_file"
    fi

done;

# For every workspace
for i in $(jq -r '.workspaces | keys | .[]' <<< $settings); do
    workspace_config=$(jq -r ".workspaces[\"$i\"]" <<< $settings);
    if [ -z "$workspace_config" ]; then
        continue;
    fi
    icon=$(jq -r '.icon' <<< $workspace_config);

    if [ -z "$icon" ]; then
        echo "No icon found for workspace $i, skipping"
        continue;
    fi
    
    # For every color
    for color_key in $(jq -r '.colors | keys | .[]' <<< $workspace_config); do
        cached_icon_file="$CACHE_ROUTE/assets/$icon-$color_key.svg"
        #  If the icon is already cached, skip
        if [ -f "$cached_icon_file" ]; then
            continue;
        fi
        
        color_value=$(jq -r ".colors[\"$color_key\"]" <<< $workspace_config);
        
        bootstrap_icon_file="/home/js/.config/ags/assets/bootstrap-icons/$icon.svg"
        
        # If the icon exists
        if [ -f "$bootstrap_icon_file" ]; then
            cache_icon "$bootstrap_icon_file" "$color_value" "$cached_icon_file"
        fi
    done
done
