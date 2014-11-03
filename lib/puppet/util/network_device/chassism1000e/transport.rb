require 'puppet/util/network_device/transport/ssh'
require 'net/ssh'
require 'uri'

module Puppet::Util::NetworkDevice::Chassism1000e 
  class Transport < Puppet::Util::NetworkDevice::Transport::Ssh
    attr_reader :hostname, :port, :username, :password
    attr_accessor :user, :password, :host, :port

    def initialize hostname, port, username, password
      @hostname = @host = hostname
      @port     = port
      @username = @user = username
      @password = password
      @default_prompt = /[$]\s?\z/n
      super()
      @timeout = Net::SSH::Connection::Session::DEFAULT_IO_SELECT_TIMEOUT
    end

    def connect
      i = 0
      begin
        super()
        #There probably shouldn't be any reason to do this, but trying to make the "least impactful changes" for now
        @client = @ssh
      rescue => e
        i += 1
         if i < 6
           Puppet.debug("Puppet::Util::NetworkDevice::Chassism1000e::Transport failed to connect. retrying in 10 seconds...")
           sleep 10
           retry
         else
          raise e
         end
      end
    end
  end
end
