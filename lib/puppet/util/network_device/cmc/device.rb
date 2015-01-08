require 'uri'
require 'puppet/util/network_device/cmc/transport'
require 'puppet/util/network_device/cmc/facts'
require '/etc/puppetlabs/puppet/modules/asm_lib/lib/security/encode'

class Puppet::Util::NetworkDevice::Cmc::Device 

  attr_accessor :url, :transport

  def initialize(url, option = {})
    @url = URI.parse(url)
    @option = option
    @url.port = 22 unless @url.port

    Puppet.debug("Puppet::Device::Cmc: connecting to Dell Chassis device #{@url.host} on port #{@url.port}")

    begin
      unencrypted_password = URI.decode(asm_decrypt(@url.password))
    rescue Exception => e
      raise Puppet::Error, "Puppet::Device::Cmc: Error decrypting the password: #{e.inspect}"
    end
    @transport ||=  Puppet::Util::NetworkDevice::Cmc::Transport.new(@url.host, @url.port, @url.user, unencrypted_password)
    @client = @transport.connect
    @client
  end

  def facts
    @facts ||= Puppet::Util::NetworkDevice::Cmc::Facts.new(@client)
    facts = @facts.retrieve
    facts
  end

end
