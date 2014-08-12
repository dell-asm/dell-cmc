Puppet::Type.type(:racadm_fw_update).provide(:racadm) do
  attr_accessor :device

  def exists?
    current_version = get_current_version
    Puppet.debug current_version
    current_version != nil
    Puppet.debug "Hi!"
    1 != 0
  end 

  def get_current_version
    begin
      output = transport.exec!('racadm getversion -m cmc-1')
      Puppet.debug output
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#get_current_version had an error -> #{e.inspect}")
      return nil
    end
    output.each_line do |l|
      if !l.start_with? '<'
        return l.split(" ")[1]
      else
        return nil
      end
    end
  end

  def transport
    if Facter.value(:url) then
      Puppet.debug "Puppet::Util::NetworkDevice::F5: connecting via facter url."
      @device ||= Puppet::Util::NetworkDevice::Racadm::Device.new(Facter.value(:url))
    else
      @device ||= Puppet::Util::NetworkDevice.current
      raise Puppet::Error, "Puppet::Util::NetworkDevice::F5: device not initialized #{caller.join("\n")}" unless @device
    end
    @device.transport.connect
  end
  

end
