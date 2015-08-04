module OpenShift

  class LBControllerException < StandardError; end

  # == Abstract load-balancer controller class
  #
  # Represents a load balancer for the OpenShift Enterprise
  # installation.  This is an abstract class.
  #
  class LoadBalancerController
    # == Abstract load-balancer pool controller object
    #
    # Represents a pool of a load balancer represented by an
    # OpenShift::LoadBalancerController object.  This is an abstract class.
    #
    class Pool
      attr_reader :name, :members

      # Add a member to the object's internal list of members.
      #
      # The arguments should be a String comprising an IP address in
      # dotted quad form and an Integer comprising a port number.
      #
      # This method does not necessarily update the load balancer
      # itself; use the update method of the corresponding
      # LoadBalancerController object to send the updated list of pool
      # members to the load balancer.
      def add_member address, port
      end

      # Remove a list of members from the object's internal list of
      # members.
      #
      # The arguments should be a String comprising an IP address in
      # dotted quad form and an Integer comprising a port number.
      #
      # This method does not necessarily update the load balancer
      # itself; use the update method of the corresponding
      # LoadBalancerController object to send the updated list of pool
      # members to the load balancer.
      def delete_member address, port
      end

      def get_aliases
      end

      # Add an alias to the object's internal list of aliases.
      #
      # The argument should be a String representing the hostname of the alias.
      #
      # This method does not necessarily update the load balancer itself; use
      # the update method of the corresponding LoadBalancerController object to
      # force an immediate update.
      def add_alias alias_str
      end

      # Remove an alias from the object's internal list of aliases.
      #
      # The argument should be a String representing the hostname of the alias.
      #
      # This method does not necessarily update the load balancer itself; use
      # the update method of the corresponding LoadBalancerController object to
      # force an immediate update.
      def delete_alias alias_str
      end

      # Add the SSL configuration for a pool's alias
      #
      # The arguments should be a String representing the hostname of the alias,
      # a String representing the x.509 SSL certificate, and a String representing
      # the private key that matches the certificate wrapped public key. The private key
      # must not have a passphrase
      #
      # This method does not necessarily update the load balancer itself; use
      # the update method of the corresponding LoadBalancerController object to
      # force an immediate update.
      def add_ssl alias_str, ssl_cert, private_key
      end

      # Remove the SSL configuration for a pool's alias
      #
      # The argument should be a String representing the hostname of the alias
      #
      # This method does not necessarily update the load balancer itself; use
      # the update method of the corresponding LoadBalancerController object to
      # force an immediate update.
      def remove_ssl alias_str
      end
    end

    # @pools is a hash that maps String to LoadBalancerPool.
    attr_reader :pools

    def create_pool pool_name
    end

    def delete_pool pool_name
    end

    # beginning of re-initialization of the daemon when it first comes up
    # or after a restart
    def reinit_start
      @lb_model.reinit_start if defined?(@lb_model) && @lb_model.respond_to?(:reinit_start)
    end

    # end of re-initialization of the daemon when it first comes up
    # or after a restart
    def reinit_end
      @lb_model.reinit_end if defined?(@lb_model) && @lb_model.respond_to?(:reinit_end)
    end
  end

end
