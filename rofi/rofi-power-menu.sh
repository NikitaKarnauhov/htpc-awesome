#!/bin/bash

. "${HOME}/.local/share/htpc-awesome/htpc-awesome-functions.sh"

script_path="${HOME}/.local/bin/rofi-power-menu.sh"

do_poweroff() {
    sudo systemctl poweroff >/dev/null 2>&1
}

do_reboot() {
    sudo systemctl reboot >/dev/null 2>&1
}

do_logout() {
    awesome-client 'awesome.quit()'
}

do_restart_awesome() {
    awesome-client 'awesome.restart()'
}

do_turn_controller_off() {
    echo "Turnoff." | socat - UNIX-CLIENT:${HOME}/.config/scc/daemon.socket >/dev/null 2>&1
}

if [[ -v "ROFI_RETV" ]]; then
    if [[ "${ROFI_RETV}" == "0" ]]; then
        echo -ne "$(gettext "Shut down")\0info\x1fcommand=do_poweroff\n"
        echo -ne "$(gettext "Reboot")\0info\x1fcommand=do_reboot\n"
        echo -ne "$(gettext "Log out")\0info\x1fcommand=do_logout\n"
        echo -ne "$(gettext "Restart window manager")\0info\x1fcommand=do_restart_awesome\n"
        echo -ne "$(gettext "Turn off controller")\0info\x1fcommand=do_turn_controller_off\n"
    elif [[ "${ROFI_RETV}" == "1" ]]; then
        declare "${ROFI_INFO}"
        if [[ -v "command" ]]; then
            ${command}
        fi
    fi
else
    awesome-client 'handle_rofi_start()'
    rofi -show power_menu -modi "power_menu:${script_path}" -config "${HOME}/.config/rofi/power-menu.rasi"
    result=$?
    awesome-client 'handle_rofi_finish()'
    exit ${result}
fi
