local theme_path = require("gears.filesystem").get_configuration_dir() .. "theme/"

local theme = {}

theme.wallpaper = function(s)
    local h = os.date("*t", os.time()).hour
    return theme_path .. "dynamic-wallpaper/lake/" .. tostring(h) .. ".jpg"
end

theme.font      = "Play 13"
theme.icon_theme = "Papirus"

theme.fg_normal  = "#DDDDDD"
theme.fg_focus   = "#FFFFFF"
theme.fg_urgent  = "#CC9393"
theme.bg_normal  = "#00000080"
theme.bg_focus   = "#2BA7D7"
theme.bg_urgent  = "#3F3F3F"
theme.bg_systray = "#000000"

theme.useless_gap   = 20
theme.border_width  = 10
theme.border_normal = "#00000080"
theme.border_focus  = "#2BA7D7"
theme.border_marked = "#CC9393"

theme.titlebar_bg_focus  = "#2BA7D7"
theme.titlebar_bg_normal = "#00000080"


theme.titlebar_close_button_focus  = theme_path .. "close.png"
theme.titlebar_close_button_normal = theme_path .. "close.png"

theme.titlebar_maximized_button_focus_active  = theme_path .. "maximized.png"
theme.titlebar_maximized_button_normal_active = theme_path .. "maximized.png"
theme.titlebar_maximized_button_focus_inactive  = theme_path .. "maximized.png"
theme.titlebar_maximized_button_normal_inactive = theme_path .. "maximized.png"

theme.titlebar_client_menu_button_focus_active  = theme_path .. "client_menu.png"
theme.titlebar_client_menu_button_normal_active = theme_path .. "client_menu.png"
theme.titlebar_client_menu_button_focus_inactive  = theme_path .. "client_menu.png"
theme.titlebar_client_menu_button_normal_inactive = theme_path .. "client_menu.png"

return theme
