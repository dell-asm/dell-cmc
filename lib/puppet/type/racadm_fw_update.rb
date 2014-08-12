Puppet::Type.newtype(:racadm_fw_update) do
  desc "racadm util to update firmware"
  ensurable do
    newvalue(:update) do
      provider.update
    end
  end

  newparam(:fw_version) do
    desc "The firmware version"

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

