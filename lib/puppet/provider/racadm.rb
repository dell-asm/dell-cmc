require 'puppet/util/network_device/racadm/device'

class Puppet::Provider::Racadm < Puppet::Provider::NetworkDevice

  def self.device(url)
    Puppet::Util::NetworkDevice::Device.new
  end

  Puppet::Type.type(:setslotname).provide :racadm do
    desc "Dell Racadm provider for setting slotname"
   
    mk_resource_methods
    def initialize(device, *args)
      super
    end

    def self.lookup(device, name)
    

end
