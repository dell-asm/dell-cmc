Puppet::Type.newtype(:chassism1000e_fw_update) do
  desc "racadm util to update firmware"

  apply_to_device

  ensurable 

  newparam(:name, :namevar => true) do
    desc "Name of the resource (pretty much meaningless)"
  end
  
  newparam(:version) do
    desc "The version that the firmware should be on"
  end

  newparam(:asm_hostname) do
    desc "The ip address for the remote location of the firmware"
    validate do |value|
      unless value =~ /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
        raise ArgumentError, "%s is not a valid IP Address" % value
      end
    end
  end

  newparam(:path) do
    desc "The path to the remote location of the firmwre (on the network share)"
    validate do |value|
      unless File.exist? value
        raise ArgumentErrorm, "The path: %x does not exist" % value
      end
    end
  end

end

