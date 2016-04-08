require 'spec_helper'

describe KumoDockerCloud::Service do
  let(:service_api) { instance_double(DockerCloud::ServiceAPI) }
  let(:docker_cloud_api) { instance_double(KumoDockerCloud::DockerCloudApi, services: service_api) }
  let(:api_service) { instance_double(DockerCloud::Service, uuid: 'service_uuid') }

  subject { described_class.new('stack_name', 'service_name', 'repository/docker_image_name') }

  before do
    allow(KumoDockerCloud::DockerCloudApi).to receive(:new).and_return(docker_cloud_api)

    allow(docker_cloud_api).to receive(:service_by_stack_and_service_name).with('stack_name', 'service_name').and_return(api_service)
  end

  describe '#update_image' do
    it 'calls the service API' do
      expect(service_api).to receive(:update).with('service_uuid', { image: "repository/docker_image_name:version"})
      subject.update_image('version')
    end
  end
end
