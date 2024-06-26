%define name    jazzhands-hotpants
%define release 0
Name:   	jazzhands-hotpants
Version:        __VERSION__
Release:        0%{?dist}
Summary:        JazzHands HOTPants clients

Group:  	System Environment/Libraries
License:        BSD
URL:    	http://www.jazzhands.net/
Source0:        %{name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-buildroot
BuildArch:	noarch
BuildRequires:	make
%if 0%{?suse_version}
BuildRequires: perl(ExtUtils::MakeMaker)
%else
BuildRequires: perl-generators
BuildRequires: perl-interpreter
%if 0%{?rhel} < 6
BuildRequires: perl(ExtUtils::MakeMaker)
%else
BuildRequires: perl-ExtUtils-MakeMaker
%endif
%endif
Requires:	jazzhands-perl-hotpants = %{version}

%description

JazzHands HOTPants clients

%package -n jazzhands-perl-hotpants
group: System Environment/Libraries
Summary: JazzHands HOTPants perl libraries
Requires: perl-Net-IP, perl-Net-DNS, perl-NetAddr-IP, jazzhands-perl-common >= 0.69.0, perl-Crypt-Rijndael, perl-Crypt-Eksblowfish, perl-Digest-HMAC, perl-Crypt-CBC, perl-DateTime-Format-Strptime, perl-URI

%package -n jazzhands-hotpants-perl-rlm
group: System Environment/Libraries
Summary: FreeRadius module for JazzHands HOTPants
Requires: jazzhands-perl-hotpants = %{version}


%description -n jazzhands-perl-hotpants
JazzHands HOTPants perl libraries

%description -n jazzhands-hotpants-perl-rlm
FreeRadius module for JazzHands HOTPants

%prep
%setup -q -n %{name}-%{version}
make  BUILDPERL=%{__perl}

%install
make  DESTDIR=%{buildroot} prefix=%{prefix} BUILDPERL=%{__perl} install

%clean
make  clean

%files -f debian/jazzhands-hotpants.install
%defattr(755,root,root,-)

%files -n jazzhands-perl-hotpants
%{perl_vendorlib}/*

%files -n jazzhands-hotpants-perl-rlm -f debian/jazzhands-hotpants-perl-rlm.install
