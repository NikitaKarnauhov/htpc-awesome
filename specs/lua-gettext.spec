%define debug_package %{nil}

Summary: Lua binding to GNU gettext package
Name: lua-gettext
Version: 0.0.git20220223
Release: 1
License: LGPL-2.1+
Source0: https://gitlab.com/sukhichev/lua-gettext/-/archive/master/lua-gettext-master.tar.gz
URL: https://gitlab.com/sukhichev/lua-gettext
Patch0: lua-gettext-lua-5.4.patch

Requires: lua, gettext
BuildRequires: gcc, lua-devel, gettext-devel

%description
lua-gettext is C module for Lua. You can use this module for
internationalization (i18n) and/or localization (l10n) with
GNU gettext.

%prep
#%setup -q -n lua-gettext-master
%autosetup -p1 -n lua-gettext-master


%build
%make_build

%install
install -D -t %{buildroot}/%{lua_libdir} gettext.so

%files
%doc LICENSE README.md README.us.md
%{lua_libdir}/gettext.so
