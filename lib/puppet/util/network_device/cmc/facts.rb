require 'puppet/util/network_device/cmc'

class Puppet::Util::NetworkDevice::Cmc::Facts

  attr_reader :client

  def initialize(transport)
    @transport = transport
  end

  def retrieve
    @facts = {}
    [ 'getchassisname',
      'getassettag'
    ].each do |k|
      output = @transport.command("racadm #{k}")
      #Output comes back something like "racadm getassettag\n00000\n$ ", so it needs to be parsed out
      @facts[k] = output.split("\n")[1..-2].first
    end
    @facts[:url] = @url
    @facts
  end

end
