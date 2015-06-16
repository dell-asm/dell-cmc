module Puppet
  module Cmc
    module Util
      attr_accessor :host, :user, :port, :password, :timeout

      def self.get_transport
        require 'asm/device_management'
        @transport ||= begin
          ASM::DeviceManagement.parse_device_config(Puppet[:certname])
        rescue
          raise Puppet::Error, "Error parsing device config for: #{Puppet[:certname]}"
        end
      end

    end
  end
end