require 'rspec'

describe KumoDockerCloud::StateValidator do
  describe '#wait_for_state' do
    subject { state_validator.wait_for_state('done', 1) }
    let(:state_validator) { described_class.new(state_provider) }
    let(:state_provider) { double('state_provider', call: {state: state_provider_state}) }

    context 'the right state' do
      let(:state_provider_state) { 'done' }

      it 'succeeds immediately if the state is right' do
        subject
      end
    end

    context 'the wrong state' do
      let(:state_provider_state) { 'not quite done' }

      it 'fails after the timeout value is reached' do
        expect { subject }.to raise_error(Timeout::Error)
      end
    end

  end

end
