#!/bin/bash

packages=(
    awesome
    rofi
    picom
    xdotool
    bluez
    python3-pydbus
    python3-gobject
    xkill
    socat
    papirus-icon-theme
    strace
)

sudo dnf install "${packages[@]}"

install -m 0644 -t "${HOME}" xresources/.Xresources

config_dir="${HOME}/.config"
local_bin_dir="${HOME}/.local/bin"
local_share_dir="${HOME}/.local/share"

install -m 0644 -t "${condig_dir}/scc/profiles" scc-profiles/*.sccprofile
sudo install -o root -g root -m 0440 -t /etc/sudoers.d sudoers/11-systemctl

install -m 0644 -t "${condig_dir}/rofi" rofi/*.rasi
install -m 0644 -t "${local_bin_dir}" rofi/*.sh

install -m 0644 -t "${local_share_dir}/fonts" fonts/*.ttf

install -m 0755 -t "${condig_dir}" awesome
