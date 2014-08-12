Puppet::Type.type(:racadm_fw_update).provide(:racadm_fw_update) do
  desc "Provides racadm support"

  attr_accessor :device

  commands :racadmcmd => "racadm"

  def self.transport
    if Facter.value(:url) then
      Puppet.debug("Puppet::Util::NetworkDevice::F4: connecting via facter url.")
      @device ||= Puppet::Util::NetworkDevice::Racadm::Device.new(Facter.value(:url))
    else
      @device ||= Puppet::Util::NetworkDevice.current
      raise Puppet::Error, "Puppet::Util::NetworkDevice::Racadm: device not initialized #{caller.join("\n")}" unless @device
    end
    Puppet.debug "#{puts @device}"
  end

  

  def update(fw_version)
    racadmcmd fwupdate, "-f 172.18.4.100", "root calvin", "-d #{:fw_version}.cmc", "-m cmc-standby"
  end

end
