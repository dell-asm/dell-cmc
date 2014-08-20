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
      output = @client.exec!('racadm getsysinfo')
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#get_current_version had an error -> #{e.inspect}")
      return nil
    end
    @client.close
    versions = {}
    output.each_line do |l|
      if l.start_with? 'Primary CMC Version'
        versions[:primary] = l.split('=')[1].gsub(' ','').chop
      elsif l.start_with? 'Standby CMC Version'
        versions[:standby] = l.split('=')[1].gsub(' ','').chop
        break
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


  #This will throw a puppet exception if the racadm update fails
  def update_status?
    begin
      transport
      output = @client.exec!('racadm fwupdate -s')
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#get_update status had error executing -> #{e.inspect}")
      raise Puppet::Error, "Puppet::Util::Network::Device::Chassism1000e: device failed"
    end
    if output.include? "Ready for firmware update"
      @client.close
      return "ready"
    elsif output.include? "Firmware update operation failed"
      error_output = get_failed_error(@client)
      @client.close
      raise Puppet::Error, "Puppet::Firmware::Chassis update failed #{error_output}"
    elsif output.include? "Firmware update in progress"
      @client.close
      Puppet.debug("Firmware update in progress")
      return "in_progress"
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
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#Chassism1000e_fw_update had an error -> #{e.inspect}")
    end
    @client.close
    sleep 20
    status = nil
    until status == "ready"
      status = update_status?
      sleep 15
    end
    true
  end


  def get_failed_error(client)
    log = client.exec!("racadm gettracelog")
    output = []
    s = false
    log.each_line do |l|
      if l.include? "Failed"
        output << l
        s = true
      elsif s and l.include? "Error"
        output << l
        s = false
      elsif s 
        output << l
      end
    end
    output.join
  end

end
