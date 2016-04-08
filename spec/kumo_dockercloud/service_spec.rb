require 'spec_helper'

describe KumoDockerCloud::Service do
  let(:service_api) { instance_double(DockerCloud::ServiceAPI) }
  let(:client) { instance_double(DockerCloud::Client, services: service_api) }
  subject { described_class.new('foo_service_name', 'foo_service_uuid', 'foo_docker_image_name') }

  before do
    allow(::DockerCloud::Client).to receive(:new).and_return(client)
    # allow(KumoDockerCloud::StateValidator).to receive(:new).and_return(state_validator)
  end

  describe '#update_image' do


    it 'calls the service API' do
      expect(service_api).to receive(:update).with('foo_service_uuid', { image: "redbubble/foo_docker_image_name:foo_version"})
      subject.update_image('foo_version')
    end
  end
  # let(:uuid) { 'foo' }
  # let(:service_name) { 'test_service' }
  # let(:app_name) { 'test_app' }
  # let(:environment_name) { 'environment' }
  # let(:app_version) { '1' }
  # let(:stacks) { double('stacks', all: [stack]) }
  # let(:stack) { instance_double(DockerCloud::Service, name: "#{app_name}-#{environment_name}", services: [service]) }
  # let(:service) { instance_doƒuble(DockerCloud::Service, uuid: uuid, name: service_name, containers: []) }
  # let(:state_validator) { instance_double(KumoDockerCloud::StateValidator) }


  # describe '#deploy' do
  #   subject { described_class.new(app_name, environment_name).deploy(service_name, app_version) }

  #   it 'uses the service api to update the image and redeploy' do
  #     expect(service_api).to receive(:update).with(uuid, {image: "redbubble/#{app_name}:#{app_version}"})
  #     expect(service_api).to receive(:redeploy).with(uuid)
  #     expect(state_validator).to receive(:wait_for_state).and_return(nil)
  #     subject
  #   end
  # end

  # describe '#deploy_wait_for_exit' do
  #   subject { described_class.new(app_name, environment_name).deploy_wait_for_exit(service_name, app_version) }
  #   let(:deployment) { instance_double(KumoDockerCloud::Deployment) }

  #   before do
  #     allow(KumoDockerCloud::Deployment).to receive(:new).and_return(deployment)
  #     allow(deployment).to receive(:app_name=)
  #     allow(deployment).to receive(:contactable=)
  #   end

  #   it 'uses the service api to update the image and redeploy' do
  #     expect(service_api).to receive(:update).with(uuid, {image: "redbubble/#{app_name}:#{app_version}"})
  #     expect(service_api).to receive(:redeploy).with(uuid)
  #     expect(deployment).to receive(:wait_for_exit_state)
  #     subject
  #   end
  # end

end
