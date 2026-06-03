#!/usr/bin/env bash
# $1 = SRC dir (directory of app.ts, passed at runtime)
SRC_DIR="${1:-/home/js/.config/dotfiles/ags-2.0}"
SETTINGS_FILE="$SRC_DIR/default-settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
  echo "No default-settings.json found at $SETTINGS_FILE"
  exit 1
fi

settings="$(cat "$SETTINGS_FILE")"

if [ -z "$settings" ]; then
  echo "Settings file is empty"
  exit 1
fi

BOOTSTRAP_ICONS_DIR="/home/js/.config/dotfiles/ags/assets/bootstrap-icons"

function cache_icon {
  local icon_file=$1
  local color=$2
  local cached_icon_file=$3
  local content
  content="$(cat "$icon_file")"
  echo "${content/fill=\"currentColor\"/fill=\"$color\"}" > "$cached_icon_file"
}

CACHE_ROUTE="$(jq -r '.cache_dir' <<< "$settings")"
mkdir -p "$CACHE_ROUTE/assets"

# Cache standalone icons (danger, etc.)
for name in $(jq -r '.icons | keys | .[]' <<< "$settings" 2>/dev/null); do
  icon_config="$(jq -r ".icons[\"$name\"]" <<< "$settings")"
  [ -z "$icon_config" ] && continue

  icon="$(jq -r '.icon' <<< "$icon_config")"
  [ -z "$icon" ] && continue
  color="$(jq -r '.color' <<< "$icon_config")"
  [ -z "$color" ] && continue

  cached_icon_file="$CACHE_ROUTE/assets/$name.svg"
  [ -f "$cached_icon_file" ] && continue

  bootstrap_icon_file="$BOOTSTRAP_ICONS_DIR/$icon.svg"
  [ -f "$bootstrap_icon_file" ] && cache_icon "$bootstrap_icon_file" "$color" "$cached_icon_file"
done

# Cache workspace icons (active/inactive/monitor variants)
for i in $(jq -r '.workspaces | keys | .[]' <<< "$settings"); do
  workspace_config="$(jq -r ".workspaces[\"$i\"]" <<< "$settings")"
  [ -z "$workspace_config" ] && continue

  icon="$(jq -r '.icon' <<< "$workspace_config")"
  [ -z "$icon" ] && continue

  for color_key in $(jq -r '.colors | keys | .[]' <<< "$workspace_config"); do
    cached_icon_file="$CACHE_ROUTE/assets/$icon-$color_key.svg"
    [ -f "$cached_icon_file" ] && continue

    color_value="$(jq -r ".colors[\"$color_key\"]" <<< "$workspace_config")"
    bootstrap_icon_file="$BOOTSTRAP_ICONS_DIR/$icon.svg"
    [ -f "$bootstrap_icon_file" ] && cache_icon "$bootstrap_icon_file" "$color_value" "$cached_icon_file"
  done
done

exit 0
