Summary: User-mode driver and GTK3 based GUI for Steam Controller
Name: sc-controller
Version: 0.4.8.6
Release: 1
License: GPL-2.0-only
Source0: sc-controller-%{version}.tar.gz
URL: https://github.com/Ryochan7/sc-controller

Requires: python3, python3-cairo, python3-setuptools, python3-gobject, gtk3, python3-pylibacl, python3-libevdev, python3-vdf, xinput
BuildRequires: gcc, python3-devel, desktop-file-utils, zlib-devel

%description
Application allowing to setup, configure and use Steam Controller
without using Steam client.

%prep
%autosetup -p1

%build
python3 setup.py build

%install
python3 setup.py install --root %{buildroot} --prefix /usr --optimize 1

%files
%doc ADDITIONAL-LICENSES LICENSE README.md TODO.md docs
%{_bindir}/scc
%{_bindir}/scc-daemon
%{_bindir}/sc-controller
%{_bindir}/scc-osd-dialog
%{_bindir}/scc-osd-keyboard
%{_bindir}/scc-osd-launcher
%{_bindir}/scc-osd-menu
%{_bindir}/scc-osd-message
%{_bindir}/scc-osd-radial-menu
%{_bindir}/scc-osd-show-bindings

/usr/lib/udev/rules.d/*.rules

%{python3_sitearch}/scc
%{python3_sitearch}/*.so
%{python3_sitearch}/*.egg-info

%{_datadir}/applications/*.desktop
%{_datadir}/icons/hicolor/24x24/status/*.png
%{_datadir}/icons/hicolor/256x256/status/*.png
%{_datadir}/pixmaps/*.svg
%{_datadir}/mime/packages/*
%{_datadir}/scc
