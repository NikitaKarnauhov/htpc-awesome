-- Source: https://stackoverflow.com/a/48474628/10784489

local surface = require("gears.surface")
local cairo = require("lgi").cairo
local timer = require("gears.timer")

-- "Mix" two surface based on a factor between 0 and 1
local function mix_surfaces(first, second, factor)
    local result = surface.duplicate_surface(first)
    local cr = cairo.Context(result)
    cr:set_source_surface(second, 0, 0)
    cr:paint_with_alpha(factor)
    return result
end

-- Get the current wallpaper and do a fade 'steps' times with 'interval'
-- seconds between steps. At each step, the wallpapers are mixed and the
-- result is given to 'callback'. If no wallpaper is set, the callback
-- function is directly called with the new wallpaper.
function fade_to_wallpaper(new_wp_file, steps, interval, callback)
    local old_wp = surface(root.wallpaper())

    -- Scale new wallpaper to match old dimensions.
    local new_wp = surface(new_wp_file)
    local new_wp_scaled = surface.duplicate_surface(old_wp)
    local cr = cairo.Context(new_wp_scaled)
    w_old, h_old = surface.get_size(old_wp)
    w_new, h_new = surface.get_size(new_wp)
    cr:scale(w_old/w_new, h_old/h_new)
    cr:set_source_surface(new_wp, 0, 0)
    cr:paint()

    if not old_wp then
        callback(new_wp_scaled)
        return
    end

    -- Setting a new wallpaper invalidates any surface returned
    -- by root.wallpaper(), so create a copy.
    old_wp = surface.duplicate_surface(old_wp)
    local steps_done = 0
    timer.start_new(interval, function()
        steps_done = steps_done + 1
        local mix = mix_surfaces(old_wp, new_wp_scaled, steps_done / steps)
        callback(mix)
        mix:finish()
        return steps_done <= steps
    end)
end
