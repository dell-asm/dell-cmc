require 'spec_helper'
require 'rspec/expectations'

describe Puppet::Type.type(:cmc_fw_update).provider(:racadm) do
  let(:resource) {Puppet::Type.type(:cmc_fw_update).new(
                                                       {
                                                           :name     => 'testFirm',
                                                           :ensure   => 'present',
                                                           :version  => '4.50',
                                                           :path     => "#{File.expand_path(File.dirname(__FILE__))}",
                                                           :hostname => '172.18.4.173'
                                                       }
  )}

  let(:provider) {resource.provider}

  before :each do
    @fixture_dir = File.join(Dir.pwd,'spec','fixtures')
    Puppet::Cmc::Util.stub(:get_transport).and_return({
                                                          :host     => '172.17.4.17',
                                                          :user     => 'root',
                                                          :password => 'password'
                                                      })
    provider.instance_variable_set(:@partitions,Array.new)
  end


  describe 'get_current_version' do
    context 'when version up-to-date' do
      it 'returns true' do
        Puppet::Cmc::Transport.any_instance.stub(:command).with('racadm getsysinfo')\
        .and_return(File.read(File.join(@fixture_dir,'getsysinfo')))
        expect(provider.get_current_version('4.50')).to be true
      end
    end
    context 'when version not up-to-date' do
      it 'returns false' do
        Puppet::Cmc::Transport.any_instance.stub(:command).with('racadm getsysinfo')\
        .and_return(File.read(File.join(@fixture_dir,'getsysinfo_ood')))
        expect(provider.get_current_version('4.50')).to be false
      end
    end
    it 'sets partitions hash' do
      expected = [
          {
              :name    => 'CMC-2',
              :status  => 'primary',
              :version => '4.40'
          },
          {
              :name    => 'CMC-1',
              :status  => 'standby',
              :version => '4.40'
          }
      ]
      Puppet::Cmc::Transport.any_instance.stub(:command).with('racadm getsysinfo')\
        .and_return(File.read(File.join(@fixture_dir,'getsysinfo_ood')))
      provider.get_current_version('4.50')
      provider.instance_variable_get(:@partitions).should == expected
    end
  end




end