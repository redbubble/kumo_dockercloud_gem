require 'spec_helper'

describe KumoDockerCloud::Deployment do
  describe '#wait_for_exit_state' do

    subject { described_class.new('test_stack', 1).wait_for_exit_state }

    let(:docker_cloud_api) { instance_double(KumoDockerCloud::DockerCloudApi, services: docker_cloud_api_services) }
    let(:docker_cloud_api_services) { double("services") }


    pending 'checks the exit state of the container that belongs to the named service' do
      allow(KumoDockerCloud::DockerCloudApi).to receive(:new).and_return(docker_cloud_api)
      expect(docker_cloud_api_services).to receive(:get).with('correct uuid')
      expect(docker_cloud_api).to receive(:service_by_stack_and_service_name).with('test_stack', 'correct_service')

      subject
    end

    it "doesn't use the uuid of the first service in the stack, it uses the correct service based on name" do
      
    end
  end
end
