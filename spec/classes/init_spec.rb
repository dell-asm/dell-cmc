require 'spec_helper'
describe 'racadm' do

  context 'with defaults for all parameters' do
    it { should contain_class('racadm') }
  end
end
