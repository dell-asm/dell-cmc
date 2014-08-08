require 'uri'
require 'puppet/util/network_device/racadm/transport'
require 'puppet/util/network_device/racadm/facts'
#require 'puppet/util/network_device/base_ftos'

class Puppet::Util::NetworkDevice::Racadm::Device #< Puppet::Util::NetworkDevice::Base_ftos

  attr_accessor :url, :transport

  def initialize(url, option = {})
    @url = URI.parse(url)
    @option = option
#    transport.default_prompt = /[$]\s?\z/n

    Puppet.debug("Puppet::Device::Racadm: connecting to Racadm device #{@url.host} on port #{@url.port}")

    raise ArgumentError, "Invalidscheme #{@url.scheme}. Must be ssh" unless @url.scheme == 'ssh'
    raise ArgumentError, "no user specified" unless @url.user
    @transport ||=  Puppet::Util::NetworkDevice::Racadm::Transport.new(@url.host, @url.port, @url.user, @url.password)
    @client = @transport.connect
    
    Puppet.debug("connected!****")

    chassisname = @client.exec!("racadm getchassisname")
    Puppet.debug("chassis name = #{chassisname}")
    @client.close
   
  end

  def facts
    @facts ||= Puppet::Util::NetworkDevice::Racadm::Facts.new(@transport)
    facts = @facts.retrieve
    facts
  end

end
