require 'uri'
require 'puppet/util/network_device/chassism1000e/transport'
require 'puppet/util/network_device/chassism1000e/facts'
require '/etc/puppetlabs/puppet/modules/asm_lib/lib/security/encode'

class Puppet::Util::NetworkDevice::Chassism1000e::Device 

  attr_accessor :url, :transport

  def initialize(url, option = {})
    @url = URI.parse(url)
    @option = option

    Puppet.debug("Puppet::Device::Chassism1000e: connecting to Chassism1000e device #{@url.host} on port #{@url.port}")

    raise ArgumentError, "Invalidscheme #{@url.scheme}. Must be ssh" unless @url.scheme == 'ssh'
    raise ArgumentError, "no user specified" unless @url.user
    begin
      unencrypted_password = URI.decode(asm_decrypt(@url.password))
    rescue Exception => e
      raise Puppet::Error, "Puppet::Device::Chassism100e: Error decrypted the password: #{e.inspect}"
    end
    @transport ||=  Puppet::Util::NetworkDevice::Chassism1000e::Transport.new(@url.host, @url.port, @url.user, unencrypted_password)
    @client = @transport.connect
    @client
  end

  def facts
    @facts ||= Puppet::Util::NetworkDevice::Chassism1000e::Facts.new(@client)
    facts = @facts.retrieve
    facts
  end

end
