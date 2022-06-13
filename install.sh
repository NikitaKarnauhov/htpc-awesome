#!/bin/bash

packages=(
    android-tools
    awesome
    bluez
    dex-autostart
    edk2-ovmf
    libX11-devel
    libXi-devel
    onboard
    papirus-icon-theme
    picom
    python3-gobject
    python3-pydbus
    qemu-nbd
    rofi
    socat
    strace
    virt-viewer
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
local_lib_dir="${HOME}/.local/lib64"

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

mkdir -p "${local_lib_dir}"
gcc -shared -fPIC -ldl android/disable_keyboard_grab.c -o "${local_lib_dir}/disable_keyboard_grab.so"

install -m 0644 -D -t "${config_dir}/systemd/user" android/android-tv.service
install -m 0644 -D -t "${HOME}/AndroidTV" android/AndroidTV.xml
install -m 0755 -D -t "${local_bin_dir}" android/android-tv.sh
install -m 0644 -D -t "${config_dir}/pipewire/pipewire.conf.d" android/10-min-quantum.conf

# virsh -c qemu:///system define AndroidTV.xml
# systemctl --user enable android-tv
