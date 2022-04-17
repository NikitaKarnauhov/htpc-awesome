#!/bin/bash

. "${HOME}/.local/share/htpc-awesome/htpc-awesome-functions.sh"

script_path="${HOME}/.local/bin/rofi-settings-menu.sh"

if [[ -v "ROFI_RETV" ]]; then
    if [[ "${ROFI_RETV}" == "0" ]]; then
        echo -ne "$(gettext "Select language")\0info\x1fsubmenu=language\n"
        echo -ne "$(gettext "Select wallpaper")\0info\x1fsubmenu=wallpaper\n"
    elif [[ "${ROFI_RETV}" == "1" ]]; then
        declare "${ROFI_INFO}"
        if [[ -v "submenu" ]]; then
            if [[ "${submenu}" == "language" ]]; then
                echo -ne "$(gettext "English")\0info\x1flanguage=en_US.utf8\n"
                echo -ne "$(gettext "Russian")\0info\x1flanguage=ru_RU.utf8\n"
            else
                awesome-client 'handle_rofi_submenu(show_wallpaper_menu)'
            fi
        elif [[ -v "language" ]]; then
            awesome-client "set_language(\"${language}\")"
        fi
    fi
else
    awesome-client 'handle_rofi_start()'
    export dynamic_wallpaper_dir="${1}"
    rofi -show settings_menu -modi "settings_menu:${script_path}" -config "${HOME}/.config/rofi/settings-menu.rasi"
    result=$?
    awesome-client 'handle_rofi_finish()'
    exit ${result}
fi
