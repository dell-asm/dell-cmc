Puppet::Type.type(:racadm_get).provide(:racadm) do
  desc "Provdes racadm support for getting resources"

  commands :racadmcmd => "racadm"

  def get(namevar,destination)
    res = transport[racadm].call(racadmcmd namevar).body
    Puppet.debug("#{namevar}: #{res}")
  end

end
