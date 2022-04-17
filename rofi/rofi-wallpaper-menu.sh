#!/bin/bash

script_path="${HOME}/.local/bin/rofi-wallpaper-menu.sh"

if [[ -v "ROFI_RETV" ]]; then
    if [[ "${ROFI_RETV}" == "0" ]]; then
        readarray -d '' wallpapers < <(find -L "${dynamic_wallpaper_dir}" -type f -path "*/thumb.jpg" -print0)
        for w in "${wallpapers[@]}"; do
            full_dir="$(dirname "${w}")"
            dir="$(basename "${full_dir}")"
            echo -ne "${dir^}\0icon\x1f${w}\x1finfo\x1fwallpaper_name=${dir}\n"
        done
    elif [[ "${ROFI_RETV}" == "1" ]]; then
        declare "${ROFI_INFO}"
        if [[ -v "wallpaper_name" ]]; then
            awesome-client "set_wallpaper_name(\"${wallpaper_name}\")"
        fi
    fi
else
    awesome-client 'handle_rofi_start()'
    export dynamic_wallpaper_dir="${1}"
    rofi -show wallpaper_menu -modi "wallpaper_menu:${script_path}" -config "${HOME}/.config/rofi/wallpaper-menu.rasi"
    result=$?
    awesome-client 'handle_rofi_finish()'
    exit ${result}
fi
