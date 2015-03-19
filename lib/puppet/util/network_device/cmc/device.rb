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
    @query = Hash.new([])
    @query = CGI.parse(@url.query) if @url.query

    Puppet.debug("Puppet::Device::Cmc: connecting to Dell Chassis device #{@url.host} on port #{@url.port}")

    user, password = get_credentials

    @transport ||=  Puppet::Util::NetworkDevice::Cmc::Transport.new(@url.host, @url.port, user, password)

    @client = @transport.connect
    @client
  end

  def get_credentials
    user = @url.user
    password = @url.password
    password = URI.decode(asm_decrypt(password)) if password

    if id = @query.fetch('credential_id', []).first
      require 'asm/cipher'
      cred = ASM::Cipher.decrypt_credential(id)
      user = cred.username
      password = cred.password
    end

    return user, password
  end

  def facts
    @facts ||= Puppet::Util::NetworkDevice::Cmc::Facts.new(@transport)
    facts = @facts.retrieve
    facts
  end
end
