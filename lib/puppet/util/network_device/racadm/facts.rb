require 'puppet/util/network_device/racadm'

class Puppet::Util::NetworkDevice::Racadm::Facts

  attr_reader :transport

  def initialize(transport)
    @transport = transport
  end

  def retrieve
    @facts = {}
    [ 'getchassisname',
      'getassettag'
    ].each do |k|
      @facts[k] = @transport.exec!(k)
    end
  end

end
