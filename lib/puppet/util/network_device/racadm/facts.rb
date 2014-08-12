require 'puppet/util/network_device/racadm'

class Puppet::Util::NetworkDevice::Racadm::Facts

  attr_reader :client

  def initialize(client)
    @client = client
  end

  def retrieve
    @facts = {}
    [ 'getchassisname',
      'getassettag'
    ].each do |k|
      @facts[k] = @client.exec!("racadm #{k}").chop
    end
    @facts[:url] = @url
    @facts
  end

end
