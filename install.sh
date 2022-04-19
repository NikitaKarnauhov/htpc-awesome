#!/bin/bash

packages=(
    awesome
    bluez
    dex-autostart
    onboard
    papirus-icon-theme
    picom
    python3-gobject
    python3-pydbus
    rofi
    socat
    strace
    xdotool
    xkb-switch
    xkill
    xset
)

sudo dnf install "${packages[@]}"

install -m 0644 -t "${HOME}" xresources/.Xresources

config_dir="${HOME}/.config"
local_bin_dir="${HOME}/.local/bin"
local_share_dir="${HOME}/.local/share"

install -m 0644 -D -t "${config_dir}/scc/profiles" scc-profiles/*.sccprofile
sudo install -o root -g root -m 0440 -t /etc/sudoers.d sudoers/11-systemctl

install -m 0644 -D -t "${config_dir}/rofi" rofi/*.rasi
install -m 0755 -D -t "${local_bin_dir}" rofi/*.sh

install -m 0644 -D -t "${config_dir}/picom" picom/*

install -m 0644 -D -t "${local_share_dir}/fonts" fonts/*.ttf
install -m 0644 -D -t "${local_share_dir}/applications" applications/*.desktop
install -m 0644 -D -t "${local_share_dir}/icons" icons/*.png icons/*.svg
install -m 0644 -D -t "${local_share_dir}/htpc-awesome" htpc-awesome/*
install -m 0644 -D -T i18n/ru.mo "${local_share_dir}/locale/ru/LC_MESSAGES/htpc-awesome.mo"

site_dir="$(python -m site --user-site)"
install -m 0644 -D -t "${site_dir}" onboard/scripts/switch_keyboard_language.py
install -m 0755 -D -t "${local_bin_dir}" onboard/*.sh
install -m 0644 -D -t "${local_share_dir}/onboard/layouts/images" onboard/layouts/images/*.svg
install -m 0644 -D -t "${local_share_dir}/onboard/layouts" onboard/layouts/*.{svg,onboard}
install -m 0644 -D -t "${local_share_dir}/onboard/themes" onboard/themes/*.theme

cp -r awesome "${config_dir}"
