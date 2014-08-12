Puppet::Type.newtype(:racadm_fw_update) do
  desc "racadm util to update firmware"

  apply_to_device

  ensurable do
    newvalue(:present) do
#      provider.update
    end
  end

  newparam(:fw_version, :namevar=>true) do
      desc "The firmware version"
  end

  newparam(:source) do
    desc "Source of the fw binary"

    validate do |value|
    end
  end
end

