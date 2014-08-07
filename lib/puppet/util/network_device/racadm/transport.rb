require 'net-ssh'

module Puppet::Util::NetworkDevice::Racadm
  class Transport
    attr_reader :hostname, :username, :password

    def initialize hostname, username, password
      @hostname = hostname
      @username = username
      @password = password
    end

    def connect
      @client = Net::SSH.start(@hostname, @username, @password)
      @client
    end
  end
end
