Puppet::Type.newtype(:racadm_fw_update) do
  desc "racadm util to update firmware"

  apply_to_device

  ensurable 

  newparam(:name, :namevar => true) do
    desc "Name of the resource (pretty much meaningless)"
  end
  
  newparam(:fw_version) do
    desc "The version that the firmware should be on"
  end

  newproperty(:catalog) do
    desc "Location of the Dell firmware catalog"
  end
  
  newproperty(:path) do
    desc "Location of the firmware binary (on the appliance)" #As of now this is relative to tftp share
  end

end

