Name:       harbour-zoo
Summary:    A small, strange, living zoo for Sailfish OS
Version:    0.1.0
Release:    1
Group:      Applications/Amusements
License:    MIT
URL:        https://github.com/nicosouv/harbour-zoo
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5Sql)
BuildRequires:  desktop-file-utils

%description
Zoo is an offline-first habit, focus and daily-challenge companion that rewards showing up with
a growing collection of odd little creatures living in animated enclosures. Gentle by design: no
streak-shaming, no timers built to stress, no telemetry. Useful because it tracks your real days;
fun because the zoo is genuinely strange and alive.

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5 "VERSION=%{version}"
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
%qmake5_install

desktop-file-install --delete-original \
  --dir %{buildroot}%{_datadir}/applications \
  %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
