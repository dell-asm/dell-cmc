require 'fileutils'

Puppet::Type.type(:cmc_fw_update).provide(:racadm) do
  attr_accessor :device

  def exists?
    @fw = {}
    @partitions = []
    @fw['version'] = resource[:version]
    @fw['path'] = resource[:path]
    @fw_host = resource[:asm_hostname]
    resource[:copy_to_tftp] ? @copy_to_tftp = resource[:copy_to_tftp] : nil
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
    primary = {}
    standby = {}
    output.each_line do |l|
      if l.start_with? 'Primary CMC Location'
        location = l.split('=')[1].strip
        primary[:name] = location
        location == "CMC-1" ? standby[:name] = "CMC-2" : standby[:name] = "CMC-1"
      elsif l.start_with? 'Primary CMC Version'
        primary[:version] = l.split('=')[1].gsub(' ','').chop
      elsif l.start_with? 'Standby CMC Version'
        standby[:version] = l.split('=')[1].gsub(' ','').chop
        break
      end
    end
    versions[:primary] = primary
    versions[:standby] = standby if standby[:version] != nil && standby[:version] != 'N/A'
    Puppet.debug("versions: #{versions}")
    versions.each do |k,v|
      if v[:version] != fw_version
        Puppet.debug "Firmware update needed for #{v[:name]}. Current version: #{v[:version]} | required version #{fw_version}"
        @partitions << {:name => v[:name], :status => k.to_s, :version => v[:version]}
      end
    end
    if @partitions.size > 0
      false
    else
      Puppet.debug 'CMC firmware versions up to date'
      true
    end
  end


  #This will throw a puppet exception if the racadm update fails
  def update_status?(cmc)
    begin
      transport
      output = @client.exec!("racadm fwupdate -s -m #{cmc}")
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#get_update status had error executing -> #{e.inspect}")
      raise Puppet::Error, "Puppet::Util::Network::Device::Cmc: device failed"
    end
    output ||= ''
    if output.include? "Ready for firmware update"
      @client.close
      Puppet.debug('Ready for firmware update')
      return "ready"
    elsif output.include? "Firmware update operation failed"
      error_output = get_failed_error(@client)
      @client.close
      raise Puppet::Error, "Puppet::Firmware::Chassis update failed #{error_output}"
    elsif output.include? "Firmware update in progress"
      @client.close
      Puppet.debug("Firmware update in progress")
      return "in_progress"
    else
      @client.close
      return "error"
    end
  end

  def transport
    @device ||= Puppet::Util::NetworkDevice.current
    raise Puppet::Error, "Puppet::Util::NetworkDevice::Cmc: device not initialized #{caller.join("\n")}" unless @device
    @client = @device.transport.connect
    @device.transport
  end

  def copy_files
    Puppet.debug("Copying files to TFTP share")
    tftp_share = @copy_to_tftp[0]
    tftp_path = @copy_to_tftp[1]
    firmware_name = tftp_path.split('/')[-1]
    full_tftp_path = tftp_share + "/" + tftp_path
    tftp_dir = full_tftp_path.split('/')[0..-2].join('/')
    if !File.exist? tftp_dir
      FileUtils.mkdir_p tftp_dir
    end
    FileUtils.cp @fw['path'], full_tftp_path
    FileUtils.chmod_R 0755, tftp_dir
    return tftp_path
  end

  def create
    if @copy_to_tftp
      location = copy_files
    else
      location = @fw['path']
    end
    modules = ''
    cmcs = []
    @partitions.each do |partition|
      partition[:status] == 'primary' ? cmc = 'cmc-active' : cmc = 'cmc-standby'
      modules << "-m #{cmc} "
      cmcs << cmc
    end
    # @partitions.each_with_index do |partition, index|
    transport
    update_cmd = "racadm fwupdate -g -u -a #{@fw_host} -d #{location} #{modules}"
    Puppet.debug('Running: ' + update_cmd)
    begin
      output = @client.exec!(update_cmd)
      Puppet.debug "#{output}"
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#cmc_fw_update had an error -> #{e.inspect}")
    end
    @client.close
    sleep 20
    status = nil
    cmcs.each do |cmc|
      until status == "ready"
        status = update_status?(cmc)
        sleep 40
      end
      Puppet.debug("CMC updated for partition: #{cmc}")
    end
    @partitions.each do |partition|
      retries = 0
      up_to_date = false
      until up_to_date
        if retries > 20 # 10 minute wait forever
          raise Puppet::Error, "Firmware version not updated after 8 minutes for #{partition[:name]}"
        end
        up_to_date = firmware_current(partition[:name])
        sleep 40
        retries += 1
      end
    end
    true
  end

  def firmware_current(fw_module)
    transport
    begin
      output = @client.exec!("racadm getversion -m #{fw_module.downcase}")
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#get_current_version had an error -> #{e.inspect}")
      false
    end
    output.each_line do |line|
      if line.start_with? fw_module.downcase
        version = line.split(" ")[1].split(".")[0..1].join "."
        Puppet.debug("Current version for #{fw_module} : #{version}. Applied version: #{@fw['version']}")
        version == @fw['version'] ? otd = true : otd = false
        return otd
      end
    end
    false
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
