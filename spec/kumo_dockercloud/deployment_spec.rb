require 'spec_helper'

describe KumoDockerCloud::Deployment do
  describe '#wait_for_exit_state' do

    subject { described_class.new('test_stack', 1).wait_for_exit_state }

    let(:state_validator) { instance_double(KumoDockerCloud::StateValidator) }

    it 'checks the exit state of the first container' do #TODO: we may want to check more containers than one
      expect(KumoDockerCloud::StateValidator).to receive(:new).and_return(state_validator)
      expect(state_validator).to receive(:wait_for_exit_state).with(240)

      subject
    end
  end
end
