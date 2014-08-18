Puppet::Type.type(:chassism1000e_fw_update).provide(:racadm) do
  attr_accessor :device

  def exists?
    if resource[:firmwares].class == Array and resource[:firmwares].count != 1
      raise Puppet::Error,  "Firmwares for the chassis update can only contain 1 and only 1 hash"
    end
    @fw = resource[:firmwares]
    @fw_host = resource[:fw_host]
    current_version = get_current_version(@fw['version'])
    current_version
  end 

  def get_current_version(fw_version)
    transport
    begin
      output = @client.exec!('racadm getversion -m cmc-1 -m cmc-2')
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#get_current_version had an error -> #{e.inspect}")
      return nil
    end
    @client.close
    versions = {}
    output.each_line do |l|
      if !l.start_with? '<'
        versions[l.split(' ')[0]] = l.split(' ')[1]
      end
    end
    Puppet.debug("versions: #{versions}")
    versions.each do |k,v|
      if v != fw_version
        Puppet.debug "Firmware update needed for #{k}. Current version: #{v} | required version #{fw_version}"
        return false
      end
    end
    Puppet.debug "CMC firmware versions up to date"
    true
  end

  def ready_to_update?
    begin
      output = @client.exec!('racadm fwupdate -s')
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#get_update status had error executing -> #{e.inspect}")
      raise Puppet::Error, "Puppet::Util::Network::Device::Chassism1000e: device failed"
    end
    if output.include? "Ready for firmware update"
      true
    else
      false
    end
  end

  def transport
    if Facter.value(:url) then
      Puppet.debug "Puppet::Util::NetworkDevice::Chassism1000e: connecting via facter url."
      @device ||= Puppet::Util::NetworkDevice::Racadm::Device.new(Facter.value(:url))
    else
      @device ||= Puppet::Util::NetworkDevice.current
      raise Puppet::Error, "Puppet::Util::NetworkDevice::Chassism1000e: device not initialized #{caller.join("\n")}" unless @device
    end
    @client = @device.transport.connect
    @device.transport
  end
  
  def create
    transport
    location = "#{@fw['path']}/firmimg.cmc"
    update_cmd = "racadm fwupdate -g -u -a #{@fw_host} -d #{location} -m cmc-standby -m cmc-active"
    begin
      Puppet.debug("Running: " + update_cmd)
      output = @client.exec!(update_cmd)
      Puppet.debug "#{output}"
      if output.include? "failed"
        raise Puppet::Error, "Puppet::Chassism1000e::Fw_update: failed #{output}"
      end
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#Chassism1000e_fw_update had an error -> #{e.inspect}")
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
