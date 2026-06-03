-- Columns layout for Hyprland — port of Qtile's Columns layout.
--
-- Commands (hyprctl dispatch layoutmsg <cmd>):
--   left / right             move focus between columns
--   up / down                move focus within column
--   next / previous          move focus linearly across all windows
--   shuffle_left / right     move focused window to adjacent column
--   shuffle_up / down        reorder window within its column
--   grow_left / right        resize column width
--   grow_up / down           resize window height within column
--   toggle_split             toggle split/stacked mode on current column
--   normalize                equal widths and heights for all
--   reset                    restore initial_ratio widths, equal heights
--   swap_column_left / right swap current column with its neighbor

local config = {
    num_columns        = 2,
    default_split      = true,
    fair               = false,
    align              = "right",  -- "left" or "right": where new columns are added
    initial_ratio      = 1,        -- ratio of first column to second (when 2 cols)
    grow_amount        = 10,
    insert_position    = 1,        -- 0 = above current window, 1 = below
    wrap_focus_columns = true,
    wrap_focus_rows    = true,
    wrap_focus_stacks  = true,
}

-- state.cols entries: { clients = {stable_id, ...}, split = bool, width = int, focus = int }
-- width and heights use proportional units: sum(widths) == 100 * #cols,
-- sum(col.heights) == 100 * #col.clients (same invariant as Qtile).
local state = {
    cols    = { { clients = {}, split = config.default_split, width = 100, focus = 1 } },
    current = 1,
    heights = {},  -- stable_id -> height unit
}

-- ─────────────────────────────────────────────────────────────
-- Utilities
-- ─────────────────────────────────────────────────────────────

local function clamp(x, lo, hi)
    return math.max(lo, math.min(hi, x))
end

local function cc()
    return state.cols[state.current]
end

local function find_col(id)
    for i, col in ipairs(state.cols) do
        for j, cid in ipairs(col.clients) do
            if cid == id then return i, j end
        end
    end
    return nil, nil
end

local function col_focused_id(col)
    if #col.clients == 0 then return nil end
    return col.clients[clamp(col.focus, 1, #col.clients)]
end

local function total_width()
    local t = 0
    for _, col in ipairs(state.cols) do t = t + col.width end
    return t
end

local function total_height(col)
    local t = 0
    for _, id in ipairs(col.clients) do t = t + (state.heights[id] or 100) end
    return t
end

-- Distribute `growth` units across `n` slots, remainder on first slot.
local function distribute(growth, n)
    if n == 0 then return {} end
    local base = math.floor(growth / n)
    local result = {}
    for i = 1, n do result[i] = base end
    result[1] = result[1] + (growth - base * n)
    return result
end

-- ─────────────────────────────────────────────────────────────
-- Column & client management (mirror Qtile's invariant exactly)
-- ─────────────────────────────────────────────────────────────

local function col_add_client(col, id, height)
    height = height or 100
    state.heights[id] = height
    local pos = clamp(col.focus + config.insert_position, 1, #col.clients + 1)
    table.insert(col.clients, pos, id)
    col.focus = pos
    -- Spread (100 - height) across the other windows so sum stays 100 * n
    local delta = 100 - height
    if delta ~= 0 and #col.clients > 1 then
        local others = {}
        for _, cid in ipairs(col.clients) do
            if cid ~= id then table.insert(others, cid) end
        end
        local g = distribute(delta, #others)
        for i, cid in ipairs(others) do
            state.heights[cid] = (state.heights[cid] or 100) + g[i]
        end
    end
end

local function col_remove_client(col, id)
    local idx
    for i, cid in ipairs(col.clients) do
        if cid == id then idx = i; break end
    end
    if not idx then return end
    local h = state.heights[id] or 100
    table.remove(col.clients, idx)
    state.heights[id] = nil
    col.focus = clamp(col.focus, 1, math.max(1, #col.clients))
    if idx <= col.focus and col.focus > 1 then col.focus = col.focus - 1 end
    -- Spread (h - 100) across remaining windows
    local delta = h - 100
    if delta ~= 0 and #col.clients > 0 then
        local g = distribute(delta, #col.clients)
        for i, cid in ipairs(col.clients) do
            state.heights[cid] = (state.heights[cid] or 100) + g[i]
        end
    end
end

local function add_column(prepend)
    local c = { clients = {}, split = config.default_split, width = 100, focus = 1 }
    if prepend then
        table.insert(state.cols, 1, c)
        state.current = state.current + 1
    else
        table.insert(state.cols, c)
    end
    -- Apply initial_ratio when transitioning from 1 to 2 columns
    if #state.cols == 2 and not config.fair then
        local sec = math.floor(200 / (1 + config.initial_ratio))
        local main_w = 200 - sec
        if prepend then
            state.cols[2].width = main_w
            c.width = sec
        else
            state.cols[1].width = main_w
            c.width = sec
        end
    end
    return c
end

local function remove_column(idx)
    if #state.cols == 1 then return end
    local dead_w = state.cols[idx].width
    table.remove(state.cols, idx)
    if idx <= state.current then
        state.current = math.max(1, state.current - 1)
    end
    local g = distribute(dead_w, #state.cols)
    for i, col in ipairs(state.cols) do col.width = col.width + g[i] end
end

-- ─────────────────────────────────────────────────────────────
-- Sync: reconcile persistent state with the current window set
-- ─────────────────────────────────────────────────────────────

local function sync_state(ctx)
    local present      = {}
    local targets_by_id = {}
    local active_id

    for _, target in ipairs(ctx.targets) do
        local w = target.window
        if w then
            present[w.stable_id]      = true
            targets_by_id[w.stable_id] = target
            if w.active then active_id = w.stable_id end
        end
    end

    -- Remove dead windows
    for i = #state.cols, 1, -1 do
        local col = state.cols[i]
        for j = #col.clients, 1, -1 do
            if not present[col.clients[j]] then
                col_remove_client(col, col.clients[j])
            end
        end
    end

    -- Remove empty columns (keep at least one)
    for i = #state.cols, 1, -1 do
        if #state.cols[i].clients == 0 and #state.cols > 1 then
            remove_column(i)
        end
    end

    -- Collect already-known ids
    local known = {}
    for _, col in ipairs(state.cols) do
        for _, id in ipairs(col.clients) do known[id] = true end
    end

    -- Add new windows following Qtile's add_client logic
    for _, target in ipairs(ctx.targets) do
        local w = target.window
        if w and not known[w.stable_id] then
            local cur  = state.cols[state.current]
            local dest = cur
            if #cur.clients > 0 and #state.cols < config.num_columns then
                local prepend = config.align == "left"
                dest = add_column(prepend)
                state.current = prepend and 1 or #state.cols
            end
            if config.fair then
                local least = 1
                for i, col in ipairs(state.cols) do
                    if #col.clients < #state.cols[least].clients then least = i end
                end
                dest = state.cols[least]
                state.current = least
            end
            col_add_client(dest, w.stable_id)
            known[w.stable_id] = true
        end
    end

    -- Track focus from Hyprland's active window
    if active_id then
        local ci, fi = find_col(active_id)
        if ci then
            state.current = ci
            state.cols[ci].focus = fi
        end
    end

    state.current = clamp(state.current, 1, #state.cols)
    for _, col in ipairs(state.cols) do
        col.focus = clamp(col.focus, 1, math.max(1, #col.clients))
    end

    return targets_by_id
end

-- ─────────────────────────────────────────────────────────────
-- Placement
-- ─────────────────────────────────────────────────────────────

local function do_recalculate(ctx)
    if #ctx.targets == 0 then return end
    local targets_by_id = sync_state(ctx)
    local area = ctx.area
    local tw   = total_width()
    if tw == 0 then return end

    local x = area.x
    for ci, col in ipairs(state.cols) do
        local col_w = (ci == #state.cols)
            and (area.x + area.w - x)
            or  math.floor(col.width * area.w / tw)

        if col.split then
            local th = total_height(col)
            local y  = area.y
            for wi, id in ipairs(col.clients) do
                local win_h = (wi == #col.clients)
                    and (area.y + area.h - y)
                    or  math.floor((state.heights[id] or 100) * area.h / th)
                local t = targets_by_id[id]
                if t then t:place({ x = x, y = y, w = col_w, h = win_h }) end
                y = y + win_h
            end
        else
            -- Stacked: all windows overlap at same box; focused window is on top.
            for _, id in ipairs(col.clients) do
                local t = targets_by_id[id]
                if t then t:place({ x = x, y = area.y, w = col_w, h = area.h }) end
            end
        end

        x = x + col_w
    end
end

-- ─────────────────────────────────────────────────────────────
-- Commands
-- ─────────────────────────────────────────────────────────────

local function cmd_left()
    if #state.cols < 2 then return end
    if config.wrap_focus_columns then
        state.current = ((state.current - 2) % #state.cols) + 1
    elseif state.current > 1 then
        state.current = state.current - 1
    end
end

local function cmd_right()
    if #state.cols < 2 then return end
    if config.wrap_focus_columns then
        state.current = (state.current % #state.cols) + 1
    elseif state.current < #state.cols then
        state.current = state.current + 1
    end
end

local function cmd_up()
    local col      = cc()
    local do_wrap  = col.split and config.wrap_focus_rows or config.wrap_focus_stacks
    if #col.clients < 2 then return end
    if do_wrap then
        col.focus = ((col.focus - 2) % #col.clients) + 1
    elseif col.focus > 1 then
        col.focus = col.focus - 1
    end
end

local function cmd_down()
    local col      = cc()
    local do_wrap  = col.split and config.wrap_focus_rows or config.wrap_focus_stacks
    if #col.clients < 2 then return end
    if do_wrap then
        col.focus = (col.focus % #col.clients) + 1
    elseif col.focus < #col.clients then
        col.focus = col.focus + 1
    end
end

local function cmd_next()
    local col = cc()
    if col.split and col.focus < #col.clients then
        col.focus = col.focus + 1
    else
        state.current = (state.current % #state.cols) + 1
        if cc().split then cc().focus = 1 end
    end
end

local function cmd_previous()
    local col = cc()
    if col.split and col.focus > 1 then
        col.focus = col.focus - 1
    else
        state.current = ((state.current - 2) % #state.cols) + 1
        if cc().split then cc().focus = #cc().clients end
    end
end

local function cmd_shuffle_left()
    local col = cc()
    local id  = col_focused_id(col)
    if not id then return end
    local h   = state.heights[id] or 100

    if state.current > 1 then
        local src_ci = state.current
        col_remove_client(col, id)
        state.current = state.current - 1
        col_add_client(cc(), id, h)
        if #col.clients == 0 then remove_column(src_ci) end
    elseif #col.clients > 1 then
        col_remove_client(col, id)
        local new_col = add_column(true)
        col_add_client(new_col, id, h)
        state.current = 1
    end
end

local function cmd_shuffle_right()
    local col    = cc()
    local id     = col_focused_id(col)
    if not id then return end
    local h      = state.heights[id] or 100
    local src_ci = state.current

    if state.current < #state.cols then
        col_remove_client(col, id)
        state.current = state.current + 1
        col_add_client(cc(), id, h)
        -- src_ci may have shifted after col_remove_client cleaned up nothing,
        -- but the column is still there until we check emptiness:
        if #state.cols > src_ci and #state.cols[src_ci].clients == 0 then
            remove_column(src_ci)
        end
    elseif #col.clients > 1 then
        col_remove_client(col, id)
        add_column(false)
        state.current = #state.cols
        col_add_client(cc(), id, h)
    end
end

local function cmd_shuffle_up()
    local col = cc()
    if col.focus > 1 then
        local i = col.focus
        col.clients[i], col.clients[i - 1] = col.clients[i - 1], col.clients[i]
        col.focus = col.focus - 1
    end
end

local function cmd_shuffle_down()
    local col = cc()
    if col.focus < #col.clients then
        local i = col.focus
        col.clients[i], col.clients[i + 1] = col.clients[i + 1], col.clients[i]
        col.focus = col.focus + 1
    end
end

local function cmd_grow_left()
    if state.current > 1 then
        local left = state.cols[state.current - 1]
        if left.width > config.grow_amount then
            left.width = left.width - config.grow_amount
            cc().width = cc().width + config.grow_amount
        end
    elseif #state.cols > 1 then
        -- Leftmost: shrink self, give to right (mirrors Qtile edge behaviour)
        if cc().width > config.grow_amount then
            state.cols[2].width = state.cols[2].width + config.grow_amount
            cc().width = cc().width - config.grow_amount
        end
    end
end

local function cmd_grow_right()
    if state.current < #state.cols then
        local right = state.cols[state.current + 1]
        if right.width > config.grow_amount then
            right.width = right.width - config.grow_amount
            cc().width = cc().width + config.grow_amount
        end
    elseif #state.cols > 1 then
        -- Rightmost: shrink self, give to left
        if cc().width > config.grow_amount then
            state.cols[state.current - 1].width = state.cols[state.current - 1].width + config.grow_amount
            cc().width = cc().width - config.grow_amount
        end
    end
end

local function cmd_grow_up()
    local col    = cc()
    local cur_id = col_focused_id(col)
    if not cur_id then return end
    if col.focus > 1 then
        local above_id = col.clients[col.focus - 1]
        if (state.heights[above_id] or 100) > config.grow_amount then
            state.heights[above_id] = state.heights[above_id] - config.grow_amount
            state.heights[cur_id]   = (state.heights[cur_id] or 100) + config.grow_amount
        end
    elseif #col.clients > 1 then
        -- Topmost: shrink self, give to below
        if (state.heights[cur_id] or 100) > config.grow_amount then
            local below_id = col.clients[col.focus + 1]
            state.heights[below_id] = (state.heights[below_id] or 100) + config.grow_amount
            state.heights[cur_id]   = state.heights[cur_id] - config.grow_amount
        end
    end
end

local function cmd_grow_down()
    local col    = cc()
    local cur_id = col_focused_id(col)
    if not cur_id then return end
    if col.focus < #col.clients then
        local below_id = col.clients[col.focus + 1]
        if (state.heights[below_id] or 100) > config.grow_amount then
            state.heights[below_id] = state.heights[below_id] - config.grow_amount
            state.heights[cur_id]   = (state.heights[cur_id] or 100) + config.grow_amount
        end
    elseif #col.clients > 1 then
        -- Bottommost: shrink self, give to above
        if (state.heights[cur_id] or 100) > config.grow_amount then
            local above_id = col.clients[col.focus - 1]
            state.heights[above_id] = (state.heights[above_id] or 100) + config.grow_amount
            state.heights[cur_id]   = state.heights[cur_id] - config.grow_amount
        end
    end
end

local function cmd_toggle_split()
    cc().split = not cc().split
end

local function cmd_normalize()
    for _, col in ipairs(state.cols) do
        col.width = 100
        for _, id in ipairs(col.clients) do state.heights[id] = 100 end
    end
end

local function cmd_reset()
    cmd_normalize()
    if config.initial_ratio == 1 or #state.cols < 2 or config.fair then return end
    local sec    = math.floor(200 / (1 + config.initial_ratio))
    local main_w = 200 - sec
    if config.align == "right" then
        state.cols[1].width = main_w
        state.cols[2].width = sec
    else
        state.cols[#state.cols].width     = main_w
        state.cols[#state.cols - 1].width = sec
    end
end

local function cmd_swap_column_left()
    local src = state.current
    local dst = src > 1 and (src - 1) or #state.cols
    state.cols[src], state.cols[dst] = state.cols[dst], state.cols[src]
    state.current = dst
end

local function cmd_swap_column_right()
    local src = state.current
    local dst = src < #state.cols and (src + 1) or 1
    state.cols[src], state.cols[dst] = state.cols[dst], state.cols[src]
    state.current = dst
end

-- ─────────────────────────────────────────────────────────────
-- Registration
-- ─────────────────────────────────────────────────────────────

local commands = {
    left             = cmd_left,
    right            = cmd_right,
    up               = cmd_up,
    down             = cmd_down,
    next             = cmd_next,
    previous         = cmd_previous,
    shuffle_left     = cmd_shuffle_left,
    shuffle_right    = cmd_shuffle_right,
    shuffle_up       = cmd_shuffle_up,
    shuffle_down     = cmd_shuffle_down,
    grow_left        = cmd_grow_left,
    grow_right       = cmd_grow_right,
    grow_up          = cmd_grow_up,
    grow_down        = cmd_grow_down,
    toggle_split     = cmd_toggle_split,
    normalize        = cmd_normalize,
    reset            = cmd_reset,
    swap_column_left  = cmd_swap_column_left,
    swap_column_right = cmd_swap_column_right,
}

hl.layout.register("columns", {
    recalculate = do_recalculate,
    layout_msg  = function(ctx, msg)
        sync_state(ctx)
        local command = msg:match("^(%S+)")
        local fn = commands[command]
        if not fn then
            return "columns: unknown command '" .. (command or "") .. "'"
        end
        fn()
        return true
    end,
})
