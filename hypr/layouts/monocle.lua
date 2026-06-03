---@module 'hl'

hl.layout.register("monocle", {
    recalculate = function(ctx)
        if #ctx.targets == 0 then return end
        local area = ctx.area
        for _, target in ipairs(ctx.targets) do
            target:place({ x = area.x, y = area.y, w = area.w, h = area.h })
        end
    end,
    layout_msg = function(_, _)
        return "monocle: no commands"
    end,
})
