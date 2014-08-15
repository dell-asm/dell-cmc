require 'uri'
require 'puppet/util/network_device/chassism1000e/transport'
require 'puppet/util/network_device/chassism1000e/facts'

class Puppet::Util::NetworkDevice::Chassism1000e::Device 

  attr_accessor :url, :transport

  def initialize(url, option = {})
    @url = URI.parse(url)
    @option = option

    Puppet.debug("Puppet::Device::Chassism1000e: connecting to Chassism1000e device #{@url.host} on port #{@url.port}")

    raise ArgumentError, "Invalidscheme #{@url.scheme}. Must be ssh" unless @url.scheme == 'ssh'
    raise ArgumentError, "no user specified" unless @url.user
    @transport ||=  Puppet::Util::NetworkDevice::Chassism1000e::Transport.new(@url.host, @url.port, @url.user, @url.password)
    @client = @transport.connect
    @client
  end

  def facts
    @facts ||= Puppet::Util::NetworkDevice::Chassism1000e::Facts.new(@client)
    facts = @facts.retrieve
    facts
  end

end
