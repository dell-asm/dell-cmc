Puppet::Type.type(:racadm_fw_update).provide(:racadm) do
  attr_accessor :device

  def exists?
    if resource[:firmwares].class == Array and resource[:firmwares].count != 1
      raise Puppet::Error,  "Firmwares for the chassis update can only contain 1 and only 1 hash"
    end
    @fw = resource[:firmwares]
    current_version = get_current_version(@fw['version'])
    current_version
  end 

  def get_current_version(fw_version)
    transport
    begin
      output = @client.exec!('racadm getversion -m cmc-1')
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#get_current_version had an error -> #{e.inspect}")
      return nil
    end
    @client.close
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

  def ready_to_update?
    begin
      output = @client.exec!('racadm fwupdate -s')
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#get_update status had error executing -> #{e.inspect}")
      raise Puppet::Error, "Puppet::Util::Network::Device::Racadm: device failed"
    end
    if output.include? "Ready for firmware update"
      true
    else
      false
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
    @client = @device.transport.connect
    @device.transport
  end
  
  def create
    transport
    location = "#{@fw['path']}/firmimg.cmc"
    update_cmd = "racadm fwupdate -g -u -a 172.18.4.100 -d #{location} -m cmc-standby"
    begin
      output = @client.exec!(update_cmd)
      Puppet.debug "#{output}"
      if output.include? "failed"
        raise Puppet::Error, "Puppet::Racadm::Fw_update: failed #{output}"
      end
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#racadm_fw_update had an error -> #{e.inspect}")
    end
    begin
      status = @client.exec!("racadm fwupdate -s")
      Puppet.debug "#{status}"
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("Checking status connection error: #{e.inspect}")
      raise Puppet::Error, "Failed to check status after update"
    end
    complete = false
    until complete
      sleep 10
      complete = ready_to_update?
    end
    @client.close
    true
  end
    
end

