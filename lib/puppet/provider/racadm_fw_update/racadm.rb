Puppet::Type.type(:racadm_fw_update).provide(:racadm) do
  desc "Provides racadm support"

  commands :racadmcmd => "racadm"

  def update(fw_version)
    racadmcmd fwupdate, "-f 172.18.4.100", "root calvin", "-d #{:fw_version}.cmc", "-m cmc-standby"
  end

end
