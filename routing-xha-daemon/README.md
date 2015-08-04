Configuring ActiveMQ
--------------------

The ActiveMQ node Routing plug-in must be enabled so that it sends 
updates that the programs in this directory can read.  Install
`rubygem-openshift-origin-routing-xha-activemq` and see its included `README.md` for
instructions.


Configuring the Daemon
----------------------

The daemon must be configured to connect to ActiveMQ. Edit
`/etc/openshift/routing-xha-daemon.conf` and set `ACTIVEMQ_USER`,
`ACTIVEMQ_PASSWORD`, `ACTIVEMQ_HOST`, and `ACTIVEMQ_DESTINATION` to the
appropriate credentials, address, and ActiveMQ destination (topic or
queue).

Exactly one routing module must be enabled.  A module that configures apache
as a load balancer is included in this repository.  Edit `/etc/openshift/routing-xha-daemon.conf` 
to set the `LOAD_BALANCER` setting to "apache" (default value) and then 
follow the configuration described below.

Internally, the routing daemon logic is divided into controllers, which
encompass higher-level logic, and models, which encompass the logic for
communicating with load balancers.  These controllers include a simple
controller that immediately dispatches commands to the load balancer, a 
controller that includes logic to batch configuration changes
and only dispatch commands to the load balancer 


Using apache
------------

Edit `/etc/openshift/routing-xha-daemon.conf` to set the appropriate values for
`APACHE_CONFDIR` and `APACHE_SERVICE`.

The daemon will automatically create and manage 
files under the directory specified by `APACHE_CONFDIR`.  After each update, the
daemon will reload the service specified by `APACHE_SERVICE`.


Generated Configuration files 
-----------------------------

By default, all configuration files are kept in /etc/httpd/conf.d/ose_routing
+ a master configuration file of /etc/httpd/conf.d/ose_routing.conf. As scalable
applications get added, the configuration files will be written to the above
directory and httpd reloaded. (tip: use 'httpd -S' to see currently active config)
When the router is re-initialized, the configuration will only be updated if
found to be different than the existing ones (i.e.: looking for deltas). This 
is accomplished by using a temporary directory (by default in '/tmp') to write
the configuration and perform a diff of existing config. If a delta is found, the
newly created (temporary) config is made "active" and httpd is reloaded. 



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

   >> mv routing-xha-daemon rubygem-openshift-origin-routing-xha-daemon-<version>
   e.g.: 
   >> mv routing-xha-daemon rubygem-openshift-origin-routing-xha-daemon-0.1.6.1

   >> tar -czf rubygem-<gem name>-<version>.tar.gz <source dir>-<version>
   e.g.:
   >> tar -czf rubygem-openshift-origin-routing-xha-daemon-0.1.6.1.tar.gz rubygem-openshift-origin-routing-xha-daemon-0.1.6.1

4. Copy the source tar.gz and spec file to the RPM build area

   >> cp rubygem-openshift-origin-routing-xha-daemon-0.1.6.1.tar.gz ~/rpmbuild/SOURCES/.
   >> cp rubygem-openshift-origin-routing-xha-daemon-0.1.6.1/rubygem-openshift-origin-routing-xha-daemon.spec ~/rpmbuild/SPECS/.

5. Build the RPM:
   >> rpmbuild -bb ~/rpmbuild/SPECS/rubygem-openshift-origin-routing-xha-daemon.spec

6. Resulting RPM is found in ~/rpmbuild/RPMS



##Notice of Export Control Law

This software distribution includes cryptographic software that is subject to the U.S. Export Administration Regulations (the "*EAR*") and other U.S. and foreign laws and may not be exported, re-exported or transferred (a) to any country listed in Country Group E:1 in Supplement No. 1 to part 740 of the EAR (currently, Cuba, Iran, North Korea, Sudan & Syria); (b) to any prohibited destination or to any end user who has been prohibited from participating in U.S. export transactions by any federal agency of the U.S. government; or (c) for use in connection with the design, development or production of nuclear, chemical or biological weapons, or rocket systems, space launch vehicles, or sounding rockets, or unmanned air vehicle systems.You may not download this software or technical information if you are located in one of these countries or otherwise subject to these restrictions. You may not provide this software or technical information to individuals or entities located in one of these countries or otherwise subject to these restrictions. You are also responsible for compliance with foreign law requirements applicable to the import, export and use of this software and technical information.
