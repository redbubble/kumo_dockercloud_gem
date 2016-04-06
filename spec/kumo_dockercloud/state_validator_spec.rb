require 'rspec'
require 'spec_helper'

describe KumoDockerCloud::StateValidator do
  describe '#wait_for_state' do
    subject { state_validator.wait_for_state('done', 1) }
    let(:state_validator) { described_class.new(state_provider) }
    let(:state_provider) { double('state_provider', call: service) }
    let(:service) { {state: service_state, name: 'service name'} }

    context 'the right state' do
      let(:service_state) { 'done' }

      it 'succeeds immediately if the state is right' do
        subject
      end
    end

    context 'the wrong state' do
      let(:service_state) { 'not quite done' }

      it 'fails after the timeout value is reached' do
        expect { subject }.to raise_error(Timeout::Error)
      end
    end

  end

  describe '#wait_for_exit_state' do
    subject { state_validator.wait_for_exit_state(1) }
    let(:state_validator) { described_class.new(state_provider) }
    let(:state_provider) { double('state_provider', call: service) }
    let(:service) { {name: 'service name', exit_code: exit_code} }

    context 'success' do
      let(:exit_code) { 0 }

      it 'succeeds immediately if the state is right' do
        subject
      end
    end

    context 'no exit before the timeout' do
      let(:exit_code) { nil }

      it 'fails' do
        expect { subject }.to raise_error(Timeout::Error)
      end
    end

  end

end
