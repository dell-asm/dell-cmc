require 'spec_helper'
describe 'cmc' do

  context 'with defaults for all parameters' do
    it { should contain_class('cmc') }
  end
end
