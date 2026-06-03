# AGS v3 Migration Context

## Status (as of 2026-05-25)

**Migration is complete and compiles cleanly.**

- All source files written and `ags bundle app.ts` produces zero errors.
- AGS v3 and all Astal libraries are installed system-wide (see Installation section).
- Not yet run live — Hyprland was not active during this session.

### To run
```bash
cd ~/.config/dotfiles/ags-2.0
ags run ./app.ts
```

### Before first run — one-time setup
```bash
# 1. Copy arch icon asset
mkdir -p ~/.config/dotfiles/ags-2.0/assets
cp ~/.config/dotfiles/ags/assets/arch-icon.png ~/.config/dotfiles/ags-2.0/assets/

# 2. Put default-settings.json in the project root (same format as the old one)
#    ags-2.0/default-settings.json  ← bar reads workspace icons from here
```

### What's NOT been tested yet
- Live rendering (needs Hyprland session)
- Battery widget (desktop may not have a battery device)
- Workspace icon colors / accent underlines
- Low-battery notify-send alert
- setup-icons.sh generating icons correctly from the new settings path

---

## Current file structure
```
ags-2.0/
├── app.ts                  # entry: app.start(), maps monitors → Bar(i)
├── env.d.ts                # declare SRC, *.scss, *.css
├── tsconfig.json           # updated by "ags types --update"
├── package.json            # { "ags": "*", "gnim": "*" } — for editor types only, not npm install
├── style.scss
├── scripts/
│   └── setup-icons.sh      # adapted from old script; takes $1=SRC_DIR, reads default-settings.json
└── widget/
    ├── Bar.tsx             # window per monitor, full layout
    ├── Head.tsx            # arch icon button → overview:toggle
    ├── Clock.tsx           # createPoll hour/min/date
    ├── Battery.tsx         # createBinding all battery props, createEffect for alert
    └── Workspace.tsx       # 8 workspaces, reactive icons/badges/monitor accent
```

### Key implementation notes
- `app.ts` calls `app.get_monitors().map((_, i) => Bar(i))` — passes integer index, not GdkMonitor
- `setup-icons.sh` is called as `exec(["bash", "${SRC}/scripts/setup-icons.sh", SRC])` — SRC passed as $1
- `default-settings.json` is read from `${SRC}/default-settings.json` (same dir as app.ts)
- Settings are a plain module-level var + `monitorFile` (no reactive state — updates are picked up next time a reactive computed re-runs, which is fine since workspaces/clients always change)
- `Widget.Fixed` pixel layout → replaced with `<overlay>` + halign/valign on icon, window-count label, danger badge
- Workspace accent color: `createComputed` over `monitors()`, finds which monitor has this workspace active, returns `"item monitor-N"` CSS class
- Urgent badge: `createComputed` over `clients()`, filters `c.urgent && c.workspace?.id === id`

---

## Installation (done, system-wide)

Packages installed via AUR (yay):
- `gtk4-layer-shell` — from `extra` repo
- `libastal-io-git`, `libastal-git`, `libastal-4-git` — Astal base
- `libastal-hyprland-git` — provides `gi://AstalHyprland`
- `libastal-battery-git` — provides `gi://AstalBattery`
- `aylurs-gtk-shell` (v3.1.0) — provides `/usr/bin/ags` CLI

**npm was broken** (system npm 11.14.1 + Node v26 had a `yallist`/`lru-cache` mismatch).
Fix applied: installed yallist v4 into npm's internal semver/lru-cache:
```
/usr/lib/node_modules/npm/node_modules/semver/node_modules/lru-cache/node_modules/yallist/
```
If npm breaks again after a system update, reapply:
```bash
curl -sL "https://registry.npmjs.org/yallist/-/yallist-4.0.0.tgz" -o /tmp/yallist4.tgz
sudo mkdir -p /usr/lib/node_modules/npm/node_modules/semver/node_modules/lru-cache/node_modules
sudo tar -xzf /tmp/yallist4.tgz -C /tmp
sudo cp -r /tmp/package /usr/lib/node_modules/npm/node_modules/semver/node_modules/lru-cache/node_modules/yallist
```

AGS modules live at `/usr/share/ags/js/` — no `npm install` needed in the project directory.

---

## AGS v3 API reference

AGS is a CLI scaffolding tool (`ags run ./app.ts`). Uses GJS + Astal + Gnim.

### Project config
```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true, "module": "ES2022", "target": "ES2020",
    "moduleResolution": "Bundler",
    "jsx": "react-jsx", "jsxImportSource": "ags/gtk4"
  }
}
```
```ts
// env.d.ts
declare const SRC: string
declare module "*.scss" { const content: string; export default content }
declare module "*.css"  { const content: string; export default content }
```

### Entry point
```tsx
import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./widget/Bar"

app.start({
  css: style,
  main() {
    app.get_monitors().map((_, i) => Bar(i))
  },
})
```

### GTK/Astal imports
```ts
import { Astal, Gtk } from "ags/gtk4"
import app from "ags/gtk4/app"
```

### JSX intrinsic elements
```tsx
<box vertical spacing={10} class="foo bar" widthRequest={200}>
  <label label="hello" />
  <button onClicked={() => {}}>
    <label label="click me" />
  </button>
  <image iconName="battery-full-symbolic" />
  <image file="/path/to/icon.svg" pixelSize={20} />
  <overlay>
    <label label="base" />
    <label label="overlay" halign={Gtk.Align.END} valign={Gtk.Align.END} />
  </overlay>
  <centerbox vertical>   // first/second/third child = start/center/end
    <label label="start" />
    <label label="center" />
    <label label="end" />
  </centerbox>
</box>
```
- `class` (not `className`)
- GTK Align: `START=1  END=2  CENTER=3  FILL=0`
- Window:
  ```tsx
  const { TOP, LEFT } = Astal.WindowAnchor
  <window monitor={0} name="bar0" anchor={TOP | LEFT} css="background: transparent;"
          margins={[top, right, bottom, left]}>
  ```

### Reactive state
```ts
import { createState, createComputed, createBinding, createEffect } from "ags"

const [count, setCount] = createState(0)
const double = createComputed(() => count() * 2)   // no side effects
createEffect(() => console.log(count()))            // side effects here

const percent = createBinding(batteryDevice, "percent")  // GObject → Accessor<number>

// In JSX — pass accessor directly for auto-updates:
<label label={createComputed(() => `${count()}`)} />
<label label={percent(p => `${p}%`)} />   // inline transform
```

### Polling
```ts
import { createPoll } from "ags/time"
const hour = createPoll("", 1000, "date +%H")
<label label={hour} />
```

### Utils
| AGS 1.x | AGS v3 |
|---|---|
| `Utils.exec(cmd)` | `exec(cmd)` from `"ags/process"` |
| `Utils.execAsync(cmd)` | `execAsync(cmd)` from `"ags/process"` |
| `Utils.readFile(path)` | `readFile(path)` from `"ags/file"` |
| `Utils.monitorFile(path, cb)` | `monitorFile(path, cb)` from `"ags/file"` |
| `Utils.merge([a, b], fn)` | `createComputed(() => fn(a(), b()))` |

`exec`/`execAsync` do NOT run in a shell — use `["bash", "-c", "..."]` for shell features.

### Hyprland
```ts
import AstalHyprland from "gi://AstalHyprland"
const hyprland = AstalHyprland.get_default()

const workspaces = createBinding(hyprland, "workspaces")  // Workspace[]
const monitors   = createBinding(hyprland, "monitors")    // Monitor[]
const clients    = createBinding(hyprland, "clients")     // Client[]

// Workspace: .id, .windows (count)
// Monitor:   .id, .activeWorkspace (Workspace | null)
// Client:    .workspace (Workspace), .urgent (bool)

hyprland.message_async("dispatch workspace 3")
hyprland.get_monitor(0)?.width   // static read at startup
```

### Battery
```ts
import AstalBattery from "gi://AstalBattery"
const device = AstalBattery.get_default().get_display_device()

createBinding(device, "percent")        // number 0-100
createBinding(device, "charging")       // boolean
createBinding(device, "icon-name")      // string
createBinding(device, "time-to-empty")  // seconds
createBinding(device, "time-to-full")   // seconds
createBinding(device, "is-present")     // boolean
```

---

## Migration decisions (AGS 1.x → v3)

1. `Widget.EventBox` → `<button>` styled flat (no border/bg in CSS)
2. `Widget.Fixed` + pixel coords → `<overlay>` + `halign`/`valign`
3. `Widget.Icon({ icon: filePath })` → `<image file={path} pixelSize={n} />`
4. `self.hook(service, cb)` → `createEffect()` or `createBinding()`
5. `App.configDir` → `SRC` global
6. `await Service.import('hyprland')` → `AstalHyprland.get_default()` at top level
7. Urgent windows → `createComputed` over `clients()`, filter `c.urgent && c.workspace?.id === id`
8. Monitor accent class → `createComputed` over `monitors()`, find where `activeWorkspace?.id === id`
9. `setup-icons.sh` → `exec(["bash", \`${SRC}/scripts/setup-icons.sh\`, SRC])`
