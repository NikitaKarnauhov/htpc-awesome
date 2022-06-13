#!/bin/bash

android_tv_root="${HOME}/AndroidTV"

command_name="$(basename "${0}")"

usage() {
	echo "${command_name} - manage Android TV virtual machine\n"
	echo "Usage: ${command_name} [--help] [COMMAND]\n"
	echo "    show          Connect and display remote UI."
	echo "    console       Copy input to VM serial console."
	echo "    start         Start VM."
	echo "    stop          Stop VM."
	echo "    plug-js       Attach gamepad to VM."
	echo "    unplug-js     Detach gamepad from VM."
	echo "    mount         Mount VM image."
	echo "    umount        Unmount VM image."
	echo "    -h, --help    Show this message."
	exit 0
}

fail() {
	message="${1}"
	echo "Error: ${message}" >&2
	exit 1
}

show() {
	export LD_PRELOAD="${HOME}/.local/lib64/disable_keyboard_grab.so"
	exec virt-viewer -c qemu:///system -a -- AndroidTV
}

console() {
	set -e
	tty_path=$(virsh -c qemu:///system dumpxml AndroidTV | xmllint --xpath 'string(//serial/source/@path)' -)
	exec cat > "${tty_path}"
}

start() {
	exec virsh -c qemu:///system start AndroidTV
}

stop() {
	set -e
	echo poweroff |console
	timeout=30
	for ((t = 0; t < timeout; ++t)); do
		(virsh -c qemu:///system list --name --state-running |grep -q "AndroidTV") || exit 0
		sleep 1
	done
	exec virsh -c qemu:///system destroy AndroidTV
}

find_js_evdev() {
	dirs=(/sys/devices/virtual/input/*)
	for dir in "${dirs[@]}"; do
		[[ -f "${dir}/name" ]] || continue
		name="$(cat "${dir}/name")"
		if [[ "${name}" == "Microsoft X-Box 360 pad" ]]; then
			evdevs=("${dir}"/event*)
			[[ ${#evdevs[@]} -gt 0 ]] || continue
			echo "/dev/input/$(basename "${evdevs[0]}")"
			return
		fi
	done
}

js_xml_path="${android_tv_root}/XBoxController.xml"

generate_js_xml() {
	js_evdev="${1}"
	echo "<input type='passthrough' bus='virtio'><source evdev='${js_evdev}'/><address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x0'/></input>"
}

plug-js() {
	js_evdev="$(find_js_evdev)"
	if [[ -z "${js_evdev}" ]]; then
		rm -rf "${js_xml_path}"
		fail "Gamepad device not found"
	fi
	generate_js_xml "${js_evdev}" > "${js_xml_path}"
	exec virsh -c qemu:///system attach-device AndroidTV "${js_xml_path}"
}

unplug-js() {
	[[ -f "${js_xml_path}" ]] || fail "Gamepad device not connected"
	exec virsh -c qemu:///system detach-device AndroidTV "${js_xml_path}"
}

mount() {
	set -e
	sudo modprobe nbd max_part=32
	sudo qemu-nbd -c /dev/nbd1 "${android_tv_root}/android_tv.qcow2"
	sudo mount /dev/nbd1p1 "${android_tv_root}/boot"
	sudo mount /dev/nbd1p2 "${android_tv_root}/data"
	sudo mount -o loop,rw "${android_tv_root}/data/android-2020-03-30/system.img" "${android_tv_root}/system"
	exit 0
}

umount() {
	set -e
	sudo umount "${android_tv_root}/system"
	sudo umount "${android_tv_root}/data"
	sudo umount "${android_tv_root}/boot"
	sudo qemu-nbd --disconnect /dev/nbd1
	exit 0
}

[ $# -gt 0 ] || show

show_help=0
action=""

while [ $# -gt 0 ]; do
	case "${1}" in
		-h|--help)
			show_help=1
			shift 1
			;;
		show|console|start|stop|plug-js|unplug-js|mount|umount)
			[ -z "${action}" ] || fail "Multiple actions requested."
			action="${1}"
			shift 1
			;;
		*)
			fail "Unexpected argument: ${1}"
			;;
	esac
done

if [ "${show_help}" != "0" ]; then
	usage
fi

${action}
