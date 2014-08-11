Puppet::Type.newtype(:racadm_fw_update) do
  desc "racadm util to update firmware"
  ensurable
  resource[:provider] = :racadm
  newparam(:fw_version) do
    desc "The firmware version"
    ensurable

    validate do |value|
    end
    isnamevar
  end

  newparam(:source) do
    desc "Source of the fw binary"

    validate do |value|
    end
  end
end

Puppet::Type.newtype(:racadm_get) do
  desc "racadm util to get info"
  ensurable
  resource[:provider] = :racadm
  newparam(:get) do 
    desc "Get info"
    ensurable
  end
#  newparam(:output) do
#    desc "Output info to destination"
#  end
end
