#!/usr/bin/env python3

from pydbus import SystemBus
from gi.repository import GLib
import subprocess
import os

def report_power(powered):
    subprocess.run(['awesome-client', 'handle_bluetooth_power({})'.format('true' if powered else 'false')])

def properties_changed_handler(iface, changed, removed):
    if 'Powered' in changed:
        report_power(changed['Powered'])

PID_FILE='/tmp/bluetooth-manager-{}.pid'.format(os.getuid())

def main():
    bus = SystemBus()

    try:
        adapter = bus.get('org.bluez', '/org/bluez/hci0')
    except:
        report_power(False)
        return

    report_power(adapter.Powered)

    if os.path.exists(PID_FILE):
        pid = open(PID_FILE).readline()
        if os.path.exists('/proc/{}'.format(pid)):
            return

    with open(PID_FILE, 'w') as f:
        f.write('{}'.format(os.getpid()))

    adapter.onPropertiesChanged = properties_changed_handler
    loop = GLib.MainLoop()
    loop.run()

if __name__ == '__main__':
    main()
