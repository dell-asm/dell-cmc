require 'net/ssh'

module Puppet::Util::NetworkDevice::Racadm
  class Transport
    attr_reader :hostname, :port, :username, :password

    def initialize hostname, port, username, password
      @hostname = hostname
      @port     = port
      @username = username
      @password = password
    end

    def connect
      @client = Net::SSH.start(@hostname, @username, {:port => @port.to_i, :password => @password})
      @client
    end
  end
end
