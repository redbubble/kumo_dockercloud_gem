require 'spec_helper'

describe KumoDockerCloud::Deployment do
  describe '#wait_for_exit_state' do

    subject { described_class.new('test_stack', 1).wait_for_exit_state }

    # let(:state_validator) { instance_double(KumoDockerCloud::StateValidator) }

    # let(:services) { [
    #   instance_double(DockerCloud::Service, name: 'wrong_service', uuid: 'wrong_uuid'),
    #   instance_double(DockerCloud::Service, name: 'correct_service', uuid: 'correct_uuid'),
    # ] }
    let(:docker_cloud_api) { instance_double(KumoDockerCloud::DockerCloudApi, services: docker_cloud_api_services) }
    let(:docker_cloud_api_services) { double("services") }
    # let(:state_validator) { instance_double(KumoDockerCloud::StateValidator, wait_for_exit_state: nil) }


    it 'checks the exit state of the container that belongs to the named service' do
      # expect(KumoDockerCloud::StateValidator).to receive(:new).and_return(state_validator)
      # expect
      allow(KumoDockerCloud::DockerCloudApi).to receive(:new).and_return(docker_cloud_api)
      expect(docker_cloud_api_services).to receive(:get).with('correct uuid')

      subject
    end

    it "doesn't use the uuid of the first service in the stack, it uses the correct service based on name" do
      
    end
  end
end
