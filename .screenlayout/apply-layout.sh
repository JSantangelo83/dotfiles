#!/bin/sh
set -u

ARANDR_SCRIPT="${1:-$HOME/.screenlayout/layout.sh}"
LOG_FILE="${XDG_RUNTIME_DIR:-/tmp}/screenlayout-fallback.log"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

run_arandr_layout() {
  if [ ! -f "$ARANDR_SCRIPT" ]; then
    log "Arandr script not found: $ARANDR_SCRIPT"
    return 1
  fi

  if [ ! -x "$ARANDR_SCRIPT" ]; then
    chmod +x "$ARANDR_SCRIPT" 2>/dev/null || true
  fi

  log "Trying arandr layout: $ARANDR_SCRIPT"
  "$ARANDR_SCRIPT"
}

build_fallback_layout() {
  xrandr --query | awk '
    function flush_output() {
      if (current_output == "") return
      if (best_mode != "") {
        printf("C\t%s\t%s\t%.2f\t%d\n", current_output, best_mode, best_rate, best_area)
      }
      current_output = ""
      best_mode = ""
      best_rate = -1
      best_area = -1
    }

    /^[^[:space:]]+[[:space:]]+connected/ {
      flush_output()
      current_output = $1
      next
    }

    /^[^[:space:]]+[[:space:]]+disconnected/ {
      flush_output()
      printf("D\t%s\n", $1)
      next
    }

    current_output != "" && $1 ~ /^[0-9]+x[0-9]+$/ {
      split($1, dims, "x")
      area = dims[1] * dims[2]

      for (i = 2; i <= NF; i++) {
        token = $i
        gsub(/[^0-9.]/, "", token)
        if (token == "") continue
        rate = token + 0

        if (rate > best_rate || (rate == best_rate && area > best_area)) {
          best_rate = rate
          best_area = area
          best_mode = $1
        }
      }
    }

    END { flush_output() }
  '
}

run_fallback_layout() {
  fallback_info="$(build_fallback_layout)"

  if [ -z "$fallback_info" ]; then
    log "Fallback failed: could not parse xrandr output"
    return 1
  fi

  cmd="$(printf '%s\n' "$fallback_info" | awk -F '\t' '
    BEGIN { cmd = "xrandr"; xpos = 0; primary = 0 }
    $1 == "D" {
      cmd = cmd " --output " $2 " --off"
      next
    }
    $1 == "C" && $2 != "" && $3 != "" {
      if (primary == 0) {
        cmd = cmd " --output " $2 " --primary --mode " $3 " --rate " $4 " --pos " xpos "x0 --rotate normal"
        primary = 1
      } else {
        cmd = cmd " --output " $2 " --mode " $3 " --rate " $4 " --pos " xpos "x0 --rotate normal"
      }
      split($3, dims, "x")
      xpos += dims[1] + 0
    }
    END { print cmd }
  ')"

  log "Applying fallback layout: $cmd"
  # shellcheck disable=SC2086
  sh -c "$cmd"
}

if run_arandr_layout; then
  log "Arandr layout applied successfully"
  exit 0
fi

log "Arandr layout failed, applying fallback"
if run_fallback_layout; then
  log "Fallback layout applied successfully"
  exit 0
fi

log "Fallback layout failed"
exit 1
