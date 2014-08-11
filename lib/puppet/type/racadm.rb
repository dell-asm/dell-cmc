Puppet::Type.newtype(:racadm_fw_update) do
  desc "racadm util to update firmware"
  ensurable

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
