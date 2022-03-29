#!/bin/bash

awesome-client 'handle_rofi_start()'
rofi -show drun -modi drun -config "${HOME}/.config/rofi/applications-menu.rasi"
result=$?
awesome-client 'handle_rofi_finish()'
exit ${result}
