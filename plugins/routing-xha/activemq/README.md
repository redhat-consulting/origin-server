Building
--------

To build a RPM from this source, please follow the steps below:
1. Use the targeted OS to perform the build (e.g.: RHEL6.x or RHEL7.x)
   Install the necessary tools:

   >> yum groupinstall "Development tools"
   >> yum install rpmdevtools rpmlint

2. Create the RPM build directories

   >> rpmdev-setuptree

3. Create a .tar.gz file from the source,

   >> mv plugins/routing-xha/activemq rubygem-openshift-origin-routing-xha-activemq-<version>
   e.g.:
   >> mv plugins/routing-xha/activemq rubygem-openshift-origin-routing-xha-activemq-0.1.6

   >> tar -czf rubygem-<gem name>-<version>.tar.gz <source dir>-<version>
   e.g.:
   >> tar -czf rubygem-openshift-origin-routing-xha-activemq-0.1.6.tar.gz rubygem-openshift-origin-routing-xha-activemq-0.1.6

4. Copy the source tar.gz and spec file to the RPM build area

   >> cp rubygem-openshift-origin-routing-xha-activemq-0.1.6.tar.gz ~/rpmbuild/SOURCES/.
   >> cp rubygem-openshift-origin-routing-xha-activemq-0.1.6/rubygem-openshift-origin-routing-xha-activemq.spec ~/rpmbuild/SPECS/.

5. Build the RPM:
   >> rpmbuild -bb ~/rpmbuild/SPECS/rubygem-openshift-origin-routing-xha-activemq.spec

6. Resulting RPM is found in ~/rpmbuild/RPMS



## Notice of Export Control Law

This software distribution includes cryptographic software that is subject to the U.S. Export Administration Regulations (the "*EAR*") and other U.S. and foreign laws and may not be exported, re-exported or transferred (a) to any country listed in Country Group E:1 in Supplement No. 1 to part 740 of the EAR (currently, Cuba, Iran, North Korea, Sudan & Syria); (b) to any prohibited destination or to any end user who has been prohibited from participating in U.S. export transactions by any federal agency of the U.S. government; or (c) for use in connection with the design, development or production of nuclear, chemical or biological weapons, or rocket systems, space launch vehicles, or sounding rockets, or unmanned air vehicle systems.You may not download this software or technical information if you are located in one of these countries or otherwise subject to these restrictions. You may not provide this software or technical information to individuals or entities located in one of these countries or otherwise subject to these restrictions. You are also responsible for compliance with foreign law requirements applicable to the import, export and use of this software and technical information.
