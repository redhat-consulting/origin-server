%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-routing-xha-daemon
%global rubyabi 1.9.1
%global appdir %{_var}/lib/openshift
%global apprundir %{_var}/run/openshift

Summary:       OpenShift daemon for Enhanced HA Routing integration
Name:          rubygem-%{gem_name}
Version: 0.1.6.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/rubygem-%{gem_name}-%{version}.tar.gz
%if 0%{?fedora} >= 19
Requires:      ruby(release)
%else
Requires:      %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
Requires:      openshift-origin-util-scl
%endif
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem(daemons)
Requires:      %{?scl:%scl_prefix}rubygem(json)
Requires:      %{?scl:%scl_prefix}rubygem(parseconfig)
Requires:      %{?scl:%scl_prefix}rubygem(stomp)
Requires:      rubygem(openshift-origin-common)
Requires:      httpd
Requires:      mod_ssl
%if 0%{?fedora}%{?rhel} <= 6
BuildRequires: scl-utils-build
%endif
%if 0%{?fedora} >= 19
BuildRequires: ruby(release)
%else
BuildRequires: %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
BuildRequires: %{?scl:%scl_prefix}rubygems
BuildRequires: %{?scl:%scl_prefix}rubygems-devel
BuildArch:     noarch

%description
OpenShift daemon for Enhanced HA Routing integration.

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}
mkdir -p .%{gem_dir}
gem build %{gem_name}.gemspec
gem install -V \
        --local \
        --install-dir ./%{gem_dir} \
        --bindir ./%{_root_bindir} \
        --force %{gem_name}-%{version}.gem
%{?scl:EOF}

%install
mkdir -p %{buildroot}/%{_var}/log/openshift

mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

mkdir -p %{buildroot}/etc/openshift
mv %{buildroot}%{gem_instdir}/conf/* %{buildroot}/etc/openshift

mkdir -p %{buildroot}/etc/rc.d/init.d/
cp -a init/* %{buildroot}/etc/rc.d/init.d/

%files
%dir %{gem_instdir}
%dir %{gem_dir}
%doc Gemfile LICENSE
%{gem_dir}/doc/%{gem_name}-%{version}
%{gem_dir}/gems/%{gem_name}-%{version}
%{gem_dir}/cache/%{gem_name}-%{version}.gem
%{gem_dir}/specifications/%{gem_name}-%{version}.gemspec
%config(noreplace) /etc/openshift/routing-xha-daemon.conf
%attr(0755,-,-) /etc/rc.d/init.d/openshift-routing-xha-daemon
%attr(0755,-,-) %{_var}/log/openshift

%changelog
* Tue Jun 30 2015 Øystein Bedin <bedin@redhat.com> 0.1.6.1-1
- First cut at the routing-xha-daemon (based on the routing-daemon)

