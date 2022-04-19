#!/bin/bash

set -e
set -x

cmd="${1}"

if [[ -z "${cmd}" ]]; then
    echo 'Error: argument required: "start", "stop", "show", "hide" or "toggle".' >&2
    exit 1
fi

pid_file="${XDG_RUNTIME_DIR}/onboard.pid"
pid=""

if [[ -f "${pid_file}" ]]; then
    pid="$(cat "${pid_file}")"
    proc_dir="/proc/${pid}"
    if [[ -d "${proc_dir}" ]]; then
        cmdline="$(cat "${proc_dir}/cmdline" |tr '\0' ' ')"
        if [[ "${cmdline}" != *"onboard"* ]]; then
            rm -f "${pid_file}"
            pid=""
        fi
    else
        rm -f "${pid_file}"
        pid=""
    fi
fi

case "${cmd}" in
    "start")
        if [[ -n "${pid}" ]]; then
            echo "Already running" >&2
            exit 1
        fi
        nohup python /usr/bin/onboard -s 960x400 -x 960 -y 680 -t HTPC -l HTPC >/dev/null 2>&1 &
        echo -n $! > "${pid_file}"
        ;;
    "stop")
        if [[ -z "${pid}" ]]; then
            echo "Already stopped" >&2
            exit 1
        fi
        kill -TERM "${pid}"
        rm -f "${pid_file}"
        ;;
    "show")
        dbus-send \
            --type=method_call \
            --dest=org.onboard.Onboard \
            /org/onboard/Onboard/Keyboard org.onboard.Onboard.Keyboard.Show
        ;;
    "hide")
        dbus-send \
            --type=method_call \
            --dest=org.onboard.Onboard \
            /org/onboard/Onboard/Keyboard org.onboard.Onboard.Keyboard.Hide
        ;;
    "toggle")
        dbus-send \
            --type=method_call \
            --dest=org.onboard.Onboard \
            /org/onboard/Onboard/Keyboard org.onboard.Onboard.Keyboard.ToggleVisible
        ;;
    *)
        echo "Error: unknown command: \"${cmd}\"." >&2
        exit 1
        ;;
esac
