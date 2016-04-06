require 'spec_helper'

describe KumoDockerCloud::Stack do
  describe '#deploy' do
    subject { described_class.new(app_name, environment_name).deploy(service_name, app_version) }

    let(:service_name) { 'test_service' }
    let(:app_name) { 'test_app' }
    let(:environment_name) { 'environment' }
    let(:app_version) { '1' }
    let(:uuid) { 'foo' }
    let(:client) { instance_double(DockerCloud::Client, stacks: stacks, services: service_api) }
    let(:service_api) { instance_double(DockerCloud::ServiceAPI) }
    let(:stacks) { double('stacks', all: [stack]) }
    let(:stack) { instance_double(DockerCloud::Stack, name: "#{app_name}-#{environment_name}", services: [service]) }
    let(:service) { instance_double(DockerCloud::Service, uuid: uuid, name: service_name, containers: []) }
    let(:state_validator) { instance_double(KumoDockerCloud::StateValidator) }

    before do
      allow(::DockerCloud::Client).to receive(:new).and_return(client)
      allow(KumoDockerCloud::StateValidator).to receive(:new).and_return(state_validator)
    end

    it 'uses the service api to update the image and redeploy' do
      expect(service_api).to receive(:update).with(uuid, {image: "redbubble/#{app_name}:#{app_version}"})
      expect(service_api).to receive(:redeploy).with(uuid)
      expect(state_validator).to receive(:wait_for_state).and_return(nil)
      subject
    end
  end
end
