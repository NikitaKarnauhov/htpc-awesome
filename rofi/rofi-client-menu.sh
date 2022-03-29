#!/bin/bash

script_path="${HOME}/.local/bin/rofi-client-menu.sh"
message_length=30

if [[ -v "ROFI_RETV" ]]; then
    if [[ "${ROFI_RETV}" == "0" ]]; then
	if [[ ${#client_name} -gt 43 ]]; then
	    client_name="$(echo "${client_name}" |cut -c -40 -)..."
	fi

        echo -ne "\0message\x1f<b>${client_name}</b>\n"
        echo -ne "\0markup-rows\x1ftrue\n"

        echo -ne "Развернуть\0info\x1fcommand=client_toggle_fullscreen(rofi_target_client)\n"
        echo -ne "Восстановить размеры окон\0info\x1fcommand=unfullscreen_all()\n"
        echo -ne "Закрыть\0info\x1fcommand=client_close(rofi_target_client)\n"

        if [[ -n "${current_auto_profile}" ]]; then
            if [[ -z "${current_custom_profile}" ]]; then
                echo -ne "<b>Профиль: Авто (${current_auto_profile}) ✔</b>\0info\x1fprofile=nil\n"
            else
                echo -ne "Профиль: Авто (${current_auto_profile})\0info\x1fprofile=nil\n"
            fi

            for filename in ${HOME}/.config/scc/profiles/*.sccprofile; do
                profile="$(basename "${filename}" .sccprofile)"
                if [[ "${profile}" == "${current_custom_profile}" ]]; then
                    echo -ne "<b>Профиль: ${profile} ✔</b>\n"
                else
                    echo -ne "Профиль: ${profile}\0info\x1fprofile=\"${profile}\"\n"
                fi
            done
        fi
    elif [[ "${ROFI_RETV}" == "1" ]]; then
        declare "${ROFI_INFO}"
        if [[ -v "command" ]]; then
            awesome-client ${command}
        elif [[ -v "profile" ]]; then
            awesome-client "set_client_profile(rofi_target_client, ${profile})"
        fi
    fi
else
    export client_name="${1}"
    export current_custom_profile="${2}"
    export current_auto_profile="${3}"
    awesome-client 'handle_rofi_start()'
    rofi -show client_menu -modi "client_menu:${script_path}" -config "${HOME}/.config/rofi/client-menu.rasi"
    result=$?
    awesome-client 'handle_rofi_finish()'
    exit ${result}
fi
