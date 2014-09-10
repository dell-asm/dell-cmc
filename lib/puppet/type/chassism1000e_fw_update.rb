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
  end

  newparam(:copy_to_tftp) do
    "2 element array, [source_path,destination_path]"
  end
    

  newparam(:path) do
    desc "The path to the remote location of the firmware (on the network share)"
    validate do |value|
      unless File.exist? value
        raise ArgumentError, "The path: %x does not exist" % value
      end
    end
  end

end

