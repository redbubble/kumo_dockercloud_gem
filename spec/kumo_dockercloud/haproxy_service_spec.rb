require 'spec_helper'

describe KumoDockerCloud::HaproxyService do
  subject { KumoDockerCloud::HaproxyService.new('stack_name') }

  describe '#disable_service' do
    subject { KumoDockerCloud::HaproxyService.new('stack_name').disable_service(service_to_disable) }
    let(:service_name) { 'the-service' }
    let(:service_to_disable) { instance_double(KumoDockerCloud::Service, :service_to_disable, name: service_name) }
    let(:container_uuid) { 'i-am-the-container'}
    let(:docker_cloud_container) { double(:docker_cloud_haproxy, uuid: container_uuid)}
    let(:containers) { [docker_cloud_container] }
    let(:docker_cloud_service) { double(:service, containers: containers) }
    let(:haproxy_container) { instance_double(KumoDockerCloud::HaproxyContainer, :haproxy_container, disable_server: nil) }
    let(:docker_cloud_client) { double }
    let(:kumo_docker_cloud_api) { instance_double(KumoDockerCloud::DockerCloudApi, :docker_cloud_api, client: docker_cloud_client ) }

    before do
      allow(KumoDockerCloud::DockerCloudApi).to receive(:new).and_return(kumo_docker_cloud_api)
      allow(kumo_docker_cloud_api).to receive(:service_by_stack_and_service_name).with('stack_name', 'haproxy').and_return(docker_cloud_service)
    end

    it 'sends the disable_server message to all its containers' do
      allow(KumoDockerCloud::HaproxyContainer).to receive(:new).with(container_uuid, docker_cloud_client).and_return(haproxy_container)
      expect(haproxy_container).to receive(:disable_server).with(service_name)
      subject
    end

    it 'blows up when there are no instances of haproxy' do
      allow(docker_cloud_service).to receive(:containers).and_return([])
      expect { subject }.to raise_error(KumoDockerCloud::HAProxyStateError, 'Could not get instances of the haproxy container for this environment')
    end
   end
end
