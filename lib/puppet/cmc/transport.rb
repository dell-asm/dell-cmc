require 'puppet/util/network_device/transport/ssh'

module Puppet
  module Cmc
    class Transport < Puppet::Util::NetworkDevice::Transport::Ssh
      attr_reader :hostname, :port, :username, :password
      attr_accessor :user, :password, :host, :port

      def initialize hostname, port, username, password
        # @transport = Puppet::Cmc::Util.get_transport
        @hostname = @host = hostname
        @port     = port
        @username = @user = username
        @password = password
        @default_prompt = /[$]\s?\z/n
        super()
        @timeout = Net::SSH::Connection::Session::DEFAULT_IO_SELECT_TIMEOUT
      end

      def connect(&block)
        begin
          Puppet.debug "Trying to connect to #{host} as #{user}"
          @ssh = Net::SSH.start(host, user, :port => port, :password => password, :timeout => timeout,
                                :paranoid => Net::SSH::Verifiers::Null.new,
                                :global_known_hosts_file=>"/dev/null")
        rescue TimeoutError
          raise TimeoutError, "SSH timed out while trying to connect to #{host}"
        rescue Net::SSH::AuthenticationFailed
          raise Puppet::Error, "SSH auth failed while trying to connect to #{host} as #{user}"
        rescue Net::SSH::Exception => error
          raise Puppet::Error, "SSH connection failure to #{host}"
        end

        @buf      = ''
        @eof      = false
        @channel  = nil
        @ssh.open_channel do |channel|
          channel.request_pty {|ch, success| raise "Failed to open PTY" unless success}

          channel.send_channel_request('shell') do |ch, success|
            raise 'Failed to open SSH SHELL Channel' unless success

            ch.on_data {|ch, data| @buf << data}
            ch.on_extended_data {|ch, type, data| @buf << data if type == 1}
            ch.on_close {@eof = true}

            @channel = ch
            expect(default_prompt, &block)
            return
          end
        end
        @ssh.loop
      end

      def command(cmd, options = {})
        begin
          attempts ||= 1
          connect unless @ssh
          super
        rescue Net::SSH::Disconnect => e
          if attempts > 3
            raise e
          else
            attempts += 1
            Puppet.err("SSH Connection was closed by remote host. Attempting to reconnect in 5 seconds...")
            sleep 5
            connect
            retry
          end
        rescue Errno::ECONNRESET => e
          Puppet.err("SSH Connection reset by peer.  Retrying in 10 seconds...")
          sleep 10
          attempts += 1
          retry
        end
      end

      #We overwrite Puppet's method here because some switches require a \r as well to work
      def send(line)
        Puppet.debug("ssh: send #{line}") if @verbose
        @channel.send_data(line + "\r")
      end
    end
  end
end