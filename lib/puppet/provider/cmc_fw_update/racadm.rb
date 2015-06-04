require 'fileutils'
require 'puppet/provider/racadm'

Puppet::Type.type(:cmc_fw_update).provide(:racadm, :parent => Puppet::Provider::Racadm) do
  attr_accessor :device

  UNZIP = %x[which unzip].chop
  FIND = %x[which find].chop

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
    begin
      conn = connection
      output = conn.command('racadm getsysinfo')
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#get_current_version had an error -> #{e.inspect}")
      return nil
    end
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
      output = connection.command("racadm fwupdate -s -m #{cmc}")
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#get_update status had error executing -> #{e.inspect}")
      raise Puppet::Error, "Puppet::Util::Network::Device::Cmc: device failed"
    end
    output ||= ''
    if output.include? "Ready for firmware update"
      Puppet.debug('Ready for firmware update')
      return "ready"
    elsif output.include? "Firmware update operation failed"
      error_output = get_failed_error(@client)
      raise Puppet::Error, "Puppet::Firmware::Chassis update failed #{error_output}"
    elsif output.include? "Firmware update in progress"
      Puppet.debug("Firmware update in progress")
      return "in_progress"
    else
      return "error"
    end
  end

  def new_binary_name
    random_string = (0...8).map { (65 + rand(26)).chr }.join
    "CMC_#{random_string }.EXE"
  end

  def rename_binary
    tftp_share = File.dirname(@fw['path'])
    new_filename = new_binary_name
    @new_file = File.join(tftp_share, new_filename)
    FileUtils.cp @fw['path'], @new_file
    FileUtils.chmod_R 0755, @new_file
    new_filename
  end

  def remove_renamed_file
    FileUtils.remove(@new_file)
  end

  def copy_files
    Puppet.debug("Copying files to TFTP share and shortening filename")
    tftp_share = @copy_to_tftp[0]
    new_filename = new_binary_name
    @new_file = tftp_share + "/" + new_filename
    FileUtils.cp @fw['path'], @new_file
    FileUtils.chmod_R 0755, @new_file
    new_filename
  end

  def unpack_binary
    dir = Dir.mktmpdir
    begin
      %x[#{UNZIP} -d #{dir} #{@fw['path']}]
      path_to_zip = %x[#{FIND} #{dir}/payload -name '*.zip']
      %x[cd #{dir}/payload && #{UNZIP} #{File.basename(path_to_zip)}]
      binary = %x[#{FIND} #{dir}/payload -name '*.bin'].chop
      {
          :tmpdir => dir,
          :binary => binary
      }
    rescue
      FileUtils.remove_entry_secure dir
      raise Puppet::Error, "Unable to un-package binary: #{@fw['path']}"
    end
  end

  def create
    begin
      Puppet.debug("Original file location: #{@fw['path']}")
      if @fw['path'].downcase.end_with? '.exe'
        unpack_info = unpack_binary
        @fw['path'] = unpack_info[:binary]
      end
      unpack_info ||= nil
      if @copy_to_tftp
        location = copy_files
      else
        location = rename_binary
      end
      modules = ''
      cmcs = []
      @partitions.each do |partition|
        partition[:status] == 'primary' ? cmc = 'cmc-active' : cmc = 'cmc-standby'
        modules << "-m #{cmc} "
        cmcs << cmc
      end
      # @partitions.each_with_index do |partition, index|
      update_cmd = "racadm fwupdate -g -u -a #{@fw_host} -d #{location} #{modules}"
      Puppet.debug('Running: ' + update_cmd)
      begin
        output = connection.command(update_cmd)
        Puppet.debug "#{output}"
      rescue Puppet::ExecutionFailure => e
        Puppet.debug("#cmc_fw_update had an error -> #{e.inspect}")
      end
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
    rescue Exception => e
      raise Puppet::Error, "General failure updating cmc: #{e.backtrace}"
    ensure
      FileUtils.remove_entry_secure unpack_info[:tmpdir] if unpack_info
      remove_renamed_file
    end
  end

  def firmware_current(fw_module)
    begin
      output = connection.command("racadm getversion -m #{fw_module.downcase}")
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


  def get_failed_error
    log = connection.command("racadm gettracelog")
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
