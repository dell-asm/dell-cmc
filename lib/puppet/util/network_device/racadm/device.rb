require 'uri'
require 'puppet/util/network_device/racadm/transport'
require 'puppet/util/network_device/racadm/facts'

class Puppet::Util::NetworkDevice::Racadm::Device

  attr_accessor :url, :transport

  def initialize(url, option = {})
    @url = URI.parse(url)
    @option = option

    Puppet.debug("Puppet::Device::Racadm: connecting to Racadm device #{@url.host}")

    raise ArgumentError, "Invalidscheme #{@url.scheme}. Must be ssh" unless @url.scheme == 'ssh'
    raise ArgumentError, "no user specified" unless @url.user
    raise ArgumentError, "no password specified" unless @url.password

    @transport ||=  Puppet::Util::NetworkDevice::Racadm::Transport.new(@url)
  end

  def facts
    @facts ||= Puppet::Util::NetworkDevice::Racadm::Facts.new(@transport)
    facts = @facts.retrieve
    facts
  end

end
