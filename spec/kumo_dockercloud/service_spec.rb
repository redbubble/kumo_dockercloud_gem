require 'httpi'

describe KumoDockerCloud::Service do
  let(:service_image) { "repository/docker_image_name:version" }
  let(:service_uuid) { "i_am_a_unique_snowflower" }
  let(:docker_cloud_service) { double(:service, uuid: service_uuid, image_name: service_image, containers: [], resource_uri: "api/v1/#{service_uuid}")}
  let(:docker_cloud_services_api) { double(:services_api) }
  let(:docker_cloud_api) { instance_double(KumoDockerCloud::DockerCloudApi, services: docker_cloud_services_api)}

  subject { described_class.new('stack_name', 'service_name') }

  before do
    allow(KumoDockerCloud::DockerCloudApi).to receive(:new).and_return(docker_cloud_api)

    allow(docker_cloud_api).to receive(:service_by_stack_and_service_name).with('stack_name', 'service_name').and_return(docker_cloud_service)
  end

  describe '#deploy' do
    it 'runs the actual update and redeploy methods' do
      expect(docker_cloud_services_api).to receive(:update).with(service_uuid, { image: service_image })
      expect(docker_cloud_services_api).to receive(:redeploy).with(service_uuid)
      subject.deploy('version')
    end

    it 'raises an appropriate exception when there is an error during image update' do
      expect(docker_cloud_services_api).to receive(:update).and_raise(RestClient::InternalServerError)
      expect { subject.deploy('version') }.to raise_error(KumoDockerCloud::ServiceDeployError, "Something went wrong during service update on Docker Cloud's end")
    end

    it 'raises an appropriate exception when there is an error during redployment' do
      allow(docker_cloud_services_api).to receive(:update).with(service_uuid, { image: service_image })
      expect(docker_cloud_services_api).to receive(:redeploy).and_raise(RestClient::InternalServerError)
      expect { subject.deploy('version') }.to raise_error(KumoDockerCloud::ServiceDeployError, "Something went wrong during service update on Docker Cloud's end")
    end
  end
end
