#!/bin/bash

script_path="${HOME}/.local/bin/rofi-bluetooth-menu.sh"

do_power_on() {
    bluetoothctl power on
}

do_power_off() {
    bluetoothctl power off
}

if [[ -v "ROFI_RETV" ]]; then
    if [[ "${ROFI_RETV}" == "0" ]]; then
        echo -ne "\0message\x1f<b>Bluetooth</b>\n"

        if [[ "${bluetooth_powered_on}" == "false" ]]; then
            echo -ne "Включить питание\0info\x1fcommand=do_power_on\n"
        else
            echo -ne "Выключить питание\0info\x1fcommand=do_power_off\n"
        fi
    elif [[ "${ROFI_RETV}" == "1" ]]; then
        declare "${ROFI_INFO}"
        if [[ -v "command" ]]; then
            ${command} > /dev/null 2>&1
        fi
    fi
else
    export bluetooth_powered_on="${1}"
    awesome-client 'handle_rofi_start()'
    rofi -show bt_menu -modi "bt_menu:${script_path}" -config "${HOME}/.config/rofi/bluetooth-menu.rasi"
    result=$?
    awesome-client 'handle_rofi_finish()'
    exit ${result}
fi
