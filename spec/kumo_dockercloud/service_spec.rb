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

  describe "#links" do
    let(:linked_service_uuid) { "i_am_the_db" }
    let(:linked_service_internal_name) { "db" }
    let(:linked_to_service) do
      {
        from_service: service_uuid,
        name: linked_service_internal_name,
        to_service: linked_service_uuid
      }
    end

    before do
      allow(docker_cloud_service).to receive(:linked_to_service).and_return([linked_to_service])
    end

    it "returns a list of KumoDockerCloud::Service object that are linked to from this service" do
      links = subject.links
      expect(links.first).to have_attributes(name: linked_service_internal_name)
      expect(links.size).to eq(1)
    end

    it "returns an empty array if there are no links" do
      allow(docker_cloud_service).to receive(:linked_to_service).and_return([])
      expect(subject.links).to eq([])
    end
  end

  describe "#set_link" do
    let(:linked_service_uuid) { "i_am_the_db" }

    let(:linked_service_internal_name) { "db" }
    let(:linked_to_service) do
      {
        to_service: "api/v1/#{linked_service_uuid}",
        name: linked_service_internal_name,
        from_service: "api/v1/#{service_uuid}"
      }
    end

    let(:linked_service) { KumoDockerCloud::Service.new('stack_name', linked_service_internal_name) }
    let(:this_service) { double(:this_service, uuid: service_uuid, resource_uri: "api/v1/#{service_uuid}") }
    let(:linked_service) { double(:linked_service, uuid: linked_service_uuid, resource_uri: "api/v1/#{linked_service_uuid}", name: linked_service_internal_name) }

    before do
      allow(docker_cloud_api).to receive(:service_by_stack_and_service_name).with('stack_name', 'service_name').and_return(this_service)
      allow(docker_cloud_api).to receive(:service_by_stack_and_service_name).with('stack_name', linked_service_internal_name).and_return(linked_service)
    end

    it "updates the link attribute" do
      expect(docker_cloud_services_api).to receive(:update).with(service_uuid, { linked_to_service: [linked_to_service] })
      subject.set_link(linked_service, linked_service_internal_name)
    end
  end

  describe "#stop" do
    it "sends a request to stop the service" do
      expect(docker_cloud_services_api).to receive(:stop).with(service_uuid)

      subject.stop
    end
  end
end
