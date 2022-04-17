#!/bin/bash

. "${HOME}/.local/share/htpc-awesome/htpc-awesome-functions.sh"

script_path="${HOME}/.local/bin/rofi-client-menu.sh"
message_length=30

if [[ -v "ROFI_RETV" ]]; then
    if [[ "${ROFI_RETV}" == "0" ]]; then
        if [[ ${#client_name} -gt 38 ]]; then
            client_name="$(echo "${client_name}" |cut -c -35 -)..."
        fi

        echo -ne "\0message\x1f<b>${client_name}</b>\n"
        echo -ne "\0markup-rows\x1ftrue\n"

        if [[ "${is_fullscreen}" == "true" ]]; then
            echo -ne "$(gettext "Unmaximize")\0info\x1fcommand=client_toggle_fullscreen(rofi_target_client)\n"
        else
            echo -ne "$(gettext "Maximize")\0info\x1fcommand=client_toggle_fullscreen(rofi_target_client)\n"
        fi

        echo -ne "$(gettext "Unmaximize all windows")\0info\x1fcommand=unfullscreen_all()\n"
        echo -ne "$(gettext "Close")\0info\x1fcommand=client_close(rofi_target_client)\n"

        if [[ -n "${current_auto_profile}" ]]; then
            if [[ -z "${current_custom_profile}" ]]; then
                echo -ne "<b>$(gettext "Profile"): $(gettext "Auto") (${current_auto_profile}) ✔</b>\0info\x1fprofile=nil\n"
            else
                echo -ne "$(gettext "Profile"): $(gettext "Auto") (${current_auto_profile})\0info\x1fprofile=nil\n"
            fi

            for filename in ${HOME}/.config/scc/profiles/*.sccprofile; do
                profile="$(basename "${filename}" .sccprofile)"
                if [[ "${profile}" == "${current_custom_profile}" ]]; then
                    echo -ne "<b>$(gettext "Profile"): ${profile} ✔</b>\n"
                else
                    echo -ne "$(gettext "Profile"): ${profile}\0info\x1fprofile=\"${profile}\"\n"
                fi
            done
        fi

        if [[ -n "${current_bypass_compositor}" ]]; then
            if [[ "${current_bypass_compositor}" == "0" ]]; then
                echo -ne "<b>$(gettext "Window redirection"): $(gettext "Auto") ✔</b>\0info\x1fbypass_compositor=0\n"
            else
                echo -ne "$(gettext "Window redirection"): $(gettext "Auto")\0info\x1fbypass_compositor=0\n"
            fi

            if [[ "${current_bypass_compositor}" == "1" ]]; then
                echo -ne "<b>$(gettext "Window redirection"): $(gettext "Off") ✔</b>\0info\x1fbypass_compositor=1\n"
            else
                echo -ne "$(gettext "Window redirection"): $(gettext "Off")\0info\x1fbypass_compositor=1\n"
            fi

            if [[ "${current_bypass_compositor}" == "2" ]]; then
                echo -ne "<b>$(gettext "Window redirection"): $(gettext "On") ✔</b>\0info\x1fbypass_compositor=2\n"
            else
                echo -ne "$(gettext "Window redirection"): $(gettext "On")\0info\x1fbypass_compositor=2\n"
            fi
        fi
    elif [[ "${ROFI_RETV}" == "1" ]]; then
        declare "${ROFI_INFO}"
        if [[ -v "command" ]]; then
            awesome-client ${command}
        elif [[ -v "profile" ]]; then
            awesome-client "set_client_profile(rofi_target_client, ${profile})"
        elif [[ -v "bypass_compositor" ]]; then
            awesome-client "set_bypass_compositor(rofi_target_client, ${bypass_compositor})"
        fi
    fi
else
    export client_name="${1}"
    export current_custom_profile="${2}"
    export current_auto_profile="${3}"
    export is_fullscreen="${4}"
    export current_bypass_compositor="${5}"
    awesome-client 'handle_rofi_start()'
    rofi -show client_menu -modi "client_menu:${script_path}" -config "${HOME}/.config/rofi/client-menu.rasi"
    result=$?
    awesome-client 'handle_rofi_finish()'
    exit ${result}
fi
