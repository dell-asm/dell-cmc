Puppet::Type.type(:racadm_fw_update).provide(:racadm) do
  attr_accessor :device

  def exists?
    current_version = get_current_version(resource[:fw_version])
    current_version
  end 

  def get_current_version(fw_version)
    begin
      output = transport.exec!('racadm getversion -m cmc-1')
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#get_current_version had an error -> #{e.inspect}")
      return nil
    end
    version = nil
    output.each_line do |l|
      if !l.start_with? '<'
        version = l.split(" ")[1]
      end
    end
    if version != fw_version
      Puppet.debug "Update needed! current version: #{version} | required version #{fw_version}"
      false
    else
      Puppet.debug "CMC fw version up to date"
      true
    end
  end

  def transport
    if Facter.value(:url) then
      Puppet.debug "Puppet::Util::NetworkDevice::Racadm: connecting via facter url."
      @device ||= Puppet::Util::NetworkDevice::Racadm::Device.new(Facter.value(:url))
    else
      @device ||= Puppet::Util::NetworkDevice.current
      raise Puppet::Error, "Puppet::Util::NetworkDevice::Racadm: device not initialized #{caller.join("\n")}" unless @device
    end
    @device.transport.connect
  end
  
  def create
    update_cmd = "racadm fwupdate -g -u -a 172.18.4.100 -d firmimg.cmc -m cmc-standby"
    begin
      output = transport.exec!(update_cmd)
      Puppet.debug "#{output}"
      if output.include? "failed"
        raise Puppet::Error, "Puppet::Racadm::Fw_update: failed #{output}"
      end
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#racadm_fw_update had an error -> #{e.inspect}")
    end
    status = transport.exec!("racadm fwupdate -s")
    Puppet.debug "#{status}"
    complete = false
    until complete
      sleep 10
      complete = get_current_version(resource[:fw_version])
    end
  end
    
end

