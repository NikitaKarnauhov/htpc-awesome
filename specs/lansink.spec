Summary: Simple audio transport over UDP
Name: lansink
Version: 0.1
Release: 1.b5a72f9
License: BSD
Source0: lansink-%{version}.tar.gz
URL: https://github.com/NikitaKarnauhov/lansink

Requires: protobuf, alsa-lib
BuildRequires: gcc-c++, cmake, alsa-lib-devel, protobuf-devel, protobuf-compiler, pkg-config

%description
LANSink is simple unreliable half-duplex audio transport over UDP implemented
as an ALSA plugin on sender side and as a stand-alone daemon on receiver side.
It currently performs no audio compression or latency control. It is designed
as a means to connect HTPC with other computers on the same network.

%prep
%autosetup -p1

%build
%cmake
%cmake_build

%install
%cmake_install

%files
%doc LICENSE README.md asoundrc.sample lansinkd.conf.sample
%{_bindir}/lansinkd
%{_libdir}/alsa-lib/libasound_module_pcm_lansink.so
