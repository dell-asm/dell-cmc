require 'puppet/util/network_device/racadm/device'

class Puppet::Provider::Racadm < Puppet::Provider

  attr_accessor :device

  def network_address(value)
    value.sub(":" + value.split(':').last, '')
  end

  def network_port(value)
    port = value.split(':').last
    port.to_i unless port == '*'
    port
  end

  def self.transport
    if Facter.value(:url) then
      Puppet.debug "Puppet::Util::NetworkDevice::Racadm: connecting via facter url."
      @device ||= Puppet::Util::NetworkDevice::Racadm::Device.new(Facter.value(:url))
    else
      @device ||= Puppet::Util::NetworkDevice.current
      raise Puppet::Error, "Puppet::Util::NetworkDevice::Racadm: device not initialzed #{caller.join("\n")}" unless @device
    end

    @transport = @device.transport
  end

  def transport
    self.class.transport
  end

end
