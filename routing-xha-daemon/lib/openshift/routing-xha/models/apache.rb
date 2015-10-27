require 'openshift/routing-xha/models/load_balancer'

require 'erb'
require 'parseconfig'
require 'uri'
require 'tmpdir'
require 'fileutils'

module OpenShift

  # == Load-balancer model class for the Apache load balancer.
  #
  class ApacheLoadBalancerModel < LoadBalancerModel

    def read_config cfgfile
      cfg = ParseConfig.new(cfgfile)

      @confdir = cfg['APACHE_CONFDIR']
      @apache_service = cfg['APACHE_SERVICE']
      @ssl_port = cfg['SSL_PORT']
      pool_name_format = cfg['POOL_NAME'] || 'pool_ose_%a_%n'
      @pool_fname_regex = Regexp.new("\\A(#{pool_name_format.gsub(/%./, '.*')})\\.pool\\Z")
      @tmp_dir = cfg['TMP_DIR'] || '/tmp'
      @tmp_prefix = cfg['TMP_PREFIX'] || 'ose-routing-'
    end

    # We manage the backend configuration by having one file per pool.  This
    # simplifies the creation, manipulation, and deletion of pools because we
    # eliminate (in the case of creation and deletion) or at least reduce (in
    # the case of manipulation) the amount of parsing we need to do to update
    # the configuration files.

    def reinit_start
      @logger.debug 'reinit_start...'
      @confdir = Dir.mktmpdir(@tmp_prefix, @tmp_dir)
      File.chmod(0755, @confdir)
      @reinit = true
    end

    def reinit_end
      @logger.debug 'reinit_end...'
      @initialized = true
      output = `diff -r #{@confdir} #{@permanent_confdir}`
      unless output.nil? || output.empty?
        @logger.info 'reinit: received updated config - reloading.'
        FileUtils.rm_r(@permanent_confdir)
        FileUtils.mv(@confdir, @permanent_confdir)
        `restorecon -R #{@permanent_confdir}`
        File.chmod(0755, @permanent_confdir)
        reload_service
      end
      FileUtils.rm_r(@confdir) if File.directory?(@confdir)
      @confdir = @permanent_confdir
      @reinit = false
    end

    # get_pool_names :: [String]
    def get_pool_names
      @logger.debug 'get_pool_names...'
      entries = []
      Dir.entries(@confdir).each do |entry|
        entries.push $1 if entry =~ @pool_fname_regex
      end
      entries
    end

    def create_pool pool_name
      @logger.debug 'create_pool...'
      fname = "#{@confdir}/#{pool_name}.pool"
      File.write(fname, '')
      File.chmod(0644, fname)
    end

    def delete_pool pool_name
      @logger.debug 'delete_pool...'
      fname = "#{@confdir}/#{pool_name}.pool"
      File.unlink(fname) if File.exist?(fname)
    end

    def get_pool_members pool_name
      @logger.debug 'get_pool_members...'
      begin
        fname = "#{@confdir}/#{pool_name}.pool"
        entries = []
        if File.exist?(fname)
          File.open(fname).each_line do |line|
            entries.push $1 if line =~ /\A\s*#\smember\s+(\S+)\s*\Z/
          end
        end
        entries
      rescue Errno::ENOENT
        raise LBModelException.new "No pool members found: #{pool_name}"
      end
    end

    alias_method :get_active_pool_members, :get_pool_members

    def add_pool_members pool_names, member_lists
      @logger.debug 'add_pool_members...'
      member_template = ERB.new(MEMBER)
      pool_names.zip(member_lists).each do |pool_name, members|
        members.push *get_pool_members(pool_name).map {|m| m.split(':')}
        servers = members.inject('') do |str, (address, port)|
          str + member_template.result(binding)
        end

        fname = "#{@confdir}/#{pool_name}.pool"
        File.write(fname, servers)
        File.chmod(0644, fname)
      end
    end

    def delete_pool_members pool_names, member_lists
      @logger.debug 'delete_pool_members...'
      member_template = ERB.new(MEMBER)

      pool_names.zip(member_lists).each do |pool_name, delete_members|
        delete_members_ = delete_members.map {|address, port| address + ':' + port.to_s}
        used_servers = []
        servers = get_pool_members(pool_name).
          reject {|member| delete_members_.include?(member)}.
          map {|member| member.split(':')}.
          map {|address, port| member_template.result(binding)}.
          join

        fname = "#{@confdir}/#{pool_name}.pool"
        File.write(fname, servers)
        File.chmod(0644, fname)
      end
    end

    def get_pool_aliases pool_name
      @logger.debug 'get_pool_aliases...'
      entries = []
      Dir.entries(@confdir).each do |entry|
        entries.push $1 if entry =~ /\Aalias_(\S+).conf\Z/
      end
      @logger.debug '..found ' + entries.length.to_s + ' aliases'
      entries
    end

    def get_alias_members alias_name
      @logger.debug 'get_alias_members...'
      fname = "#{@confdir}/alias_#{alias_name}.conf"
      entries = Hash.new
      if File.exist?(fname)
        File.open(fname).each_line do |line|
          entries[$2] = $1 if line =~ /\A\s*#\sBalancerMember ([^;]+);(\S+)\s*\Z/
        end
      end
      entries
    end

    def add_pool_alias pool_name, alias_str, public_ip, public_port
      @logger.debug 'add_pool_alias...'
      return if public_ip.empty? || public_ip.nil?
      fname = "#{@confdir}/alias_#{alias_str}.conf"
      entries = get_alias_members alias_str
      alias_template = ERB.new(ALIAS)
      entries[pool_name] = "#{public_ip}:#{public_port}"
      File.write(fname, alias_template.result(binding))
      File.chmod(0644, fname)
      reload_service unless @reinit
    end

    def delete_pool_alias pool_name, alias_str
      @logger.debug 'delete_pool_alias...'
      fname = "#{@confdir}/alias_#{alias_str}.conf"
      entries = get_alias_members alias_str
      entries.delete(pool_name)
      if entries.empty?
        File.unlink(fname) if File.exist?(fname)
      else
        alias_template = ERB.new(ALIAS)
        File.write(fname, alias_template.result(binding))
        File.chmod(0644, fname)
      end
      reload_service unless @reinit
    end

    def get_pool_certificates pool_name
      @logger.debug 'get_pool_certificates...'
      entries = []
      entries
    end

    def add_ssl pool_name, alias_str, ssl_cert, private_key
      @logger.debug 'add_ssl...'
      FileUtils.mkdir_p("#{@confdir}/#{@certs_dir}", :mode => 0755)

      fname_crt = "#{@confdir}/#{@certs_dir}/#{alias_str}.crt"
      fname_key = "#{@confdir}/#{@certs_dir}/#{alias_str}.key"
      File.write(fname_crt, ssl_cert);
      File.chmod(0644, fname_crt)
      File.write(fname_key, private_key);
      File.chmod(0644, fname_key)
      `restorecon -R #{@confdir}`

      # Enable the alias specific certs in the configuration and
      # disable the default ones
      fname = "#{@confdir}/alias_#{alias_str}.conf"
      confdata = File.read(fname)
      confdata.gsub!(/(^\s+)(SSLCertificateFile.+localhost.*.crt)/, "\\1# \\2")
      confdata.gsub!(/(^\s+)(SSLCertificateKeyFile.+localhost.*.key)/, "\\1# \\2")
      confdata.gsub!(/(^\s+)# (SSLCertificateFile.+#{alias_str}.*.crt)/, "\\1\\2")
      confdata.gsub!(/(^\s+)# (SSLCertificateKeyFile.+#{alias_str}.*.key)/, "\\1\\2")
      File.open(fname, 'w') do |fh|
        fh << confdata
      end

      # Reload to activate the latest changes
      reload_service unless @reinit
    end

    def remove_ssl pool_name, alias_str
      @logger.debug 'remove_ssl...'
      fname_crt = "#{@confdir}/#{@certs_dir}/#{alias_str}.crt"
      fname_key = "#{@confdir}/#{@certs_dir}/#{alias_str}.key"
      File.unlink(fname_crt) if File.exist?(fname_crt)
      File.unlink(fname_key) if File.exist?(fname_key)

      # Enable the default certs in the configuration and
      # disable the alias specific ones
      fname = "#{@confdir}/alias_#{alias_str}.conf"
      confdata = File.read(fname)
      confdata.gsub!(/(^\s+)# (SSLCertificateFile.+localhost.*.crt)/, "\\1\\2")
      confdata.gsub!(/(^\s+)# (SSLCertificateKeyFile.+localhost.*.key)/, "\\1\\2")
      confdata.gsub!(/(^\s+)(SSLCertificateFile.+#{alias_str}.*.crt)/, "\\1# \\2")
      confdata.gsub!(/(^\s+)(SSLCertificateKeyFile.+#{alias_str}.*.key)/, "\\1# \\2")
      File.open(fname, 'w') do |fh|
        fh << confdata
      end

      # Reload to activate the latest changes
      reload_service unless @reinit
    end

    def reload_service
      @logger.debug 'reload_service...'
      unless @initialized
        @logger.info 'daemon not initalized yet.'
        return
      end

      system("service #{@apache_service} status")
      if $?.exitstatus == 0
        @logger.debug 'daemon operational, reloading...'
        `service #{@apache_service} reload`
      else
        @logger.info 'daemon not running, starting/restarting service...'
        `service #{@apache_service} restart`
      end
    end

    def initialize logger, cfgfile
      @logger = logger
      @logger.info 'Initializing apache model...'
      @certs_dir = 'certs'
      @reinit = false
      @initialized = false

      read_config cfgfile

      # Ensure that the apache service isn't running by default
      # - this to avoid that the daemon is using stale/old data
      `chkconfig #{@apache_service} off`
      `service #{@apache_service} stop`

      # Ensure the sub directory is added to the main configuration
      # - and that conf files in the sub directory are sourced
      orig_confdir = @confdir
      @confdir = @confdir + '/ose_routing'
      @permanent_confdir = @confdir

      # First, clean-out existing "old" configuration
      FileUtils.rm_r(@confdir) if File.directory?(@confdir)

      # Second, make sure the directory exists
      FileUtils.mkdir_p(@confdir, :mode => 0755)
      `restorecon -R #{@confdir}`

      # Include the new configuration
      File.write("#{orig_confdir}/ose_routing.conf", "NameVirtualHost *:443\nInclude #{@confdir}/*.conf\n")
      File.chmod(0644, "#{orig_confdir}/ose_routing.conf")
    end

    ALIAS = %q{
<VirtualHost *:<%= @ssl_port %>>
    ErrorLog logs/<%= alias_str %>-error_log

    ProxyRequests off
    ProxyStatus on
    ProxyPreserveHost On
    ServerName <%= alias_str %>
    ProxyPass / balancer://<%= alias_str %>/

    SSLEngine on
    # SSLCertificateFile <%= @permanent_confdir %>/<%= @certs_dir %>/<%= alias_str %>.crt
    # SSLCertificateKeyFile <%= @permanent_confdir %>/<%= @certs_dir %>/<%= alias_str %>.key

    # SSL Defaults for this vhost
    SSLProtocol ALL -SSLv2 -SSLv3
    SSLHonorCipherOrder On
    # These are recommendations based on known cipher research as of March 2014;
    # please consult your own security experts to determine your own appropriate settings.
    SSLCipherSuite kEECDH:+kEECDH+SHA:kEDH:+kEDH+SHA:+kEDH+CAMELLIA:kECDH:+kECDH+SHA:kRSA:+kRSA+SHA:+kRSA+CAMELLIA:!aNULL:!eNULL:!SSLv2:!RC4:!DES:!EXP:!SEED:!IDEA:+3DES

    SSLCertificateFile /etc/pki/tls/certs/localhost.crt
    SSLCertificateKeyFile /etc/pki/tls/private/localhost.key

    <Proxy balancer://<%= alias_str %>>
<%
     entries.each do |pool_name, bm|
%>
        # BalancerMember <%= bm %>;<%= pool_name %>
        BalancerMember http://<%= bm %>
<%  end %>

        Order Deny,Allow
        Deny from none
        Allow from all

        # Load Balancer Settings
        # We will be configuring a simple Round
        # Robin style load balancer.  This means
        # that all webheads take an equal share of
        # of the load.
        ProxySet lbmethod=byrequests

    </Proxy>
</VirtualHost>

}

    MEMBER = %q{
# member <%= address %>:<%= port %>
}


  end

end
