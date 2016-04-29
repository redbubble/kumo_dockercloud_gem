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

  describe '#check' do
    let(:http_lib) { double('http_lib') }
    let(:container_status_check) { lambda { |container| container.state == 'Running' } }
    let(:endpoint_check) do
      lambda do |container|
        url = "#{container.container_ports.first[:endpoint_uri]}/site_status"
        response = http_lib.get(url)
        response == 200
      end
    end
    let(:checks) {[container_status_check, endpoint_check]}
    let(:check_timeout) { 300 }
    let(:whale1) { double(:whale1, container_ports: [{endpoint_uri: "http://whale1.test"}], reload: nil) }
    let(:whale2) { double(:whale2, state: "Running", container_ports: [{endpoint_uri: "http://whale2.test"}], reload: nil)}
    let(:containers) { [whale1, whale2] }

    before do
      allow(http_lib).to receive(:get).with("http://whale1.test/site_status").and_return(200)
      allow(http_lib).to receive(:get).with("http://whale2.test/site_status").and_return("timeout", "timeout", 200)
      allow(whale1).to receive(:state).and_return("Starting", "Running")
      allow(docker_cloud_service).to receive(:containers).and_return(containers)
    end

    it 'runs without incident' do
      allow(subject).to receive(:sleep).and_return(nil)
      subject.check(checks, check_timeout)
    end

    it 'raises an error if any check fails to pass within the timeout period' do
      short_timeout = 2
      allow(whale1).to receive(:state).and_return("Starting")
      expect { subject.check(checks, short_timeout) }.to raise_error(KumoDockerCloud::ServiceDeployError, "One or more checks failed to pass within the timeout")
    end

    describe "#links" do
      let(:linked_service_uuid) { "i_am_the_db" }
      let(:linked_service_name) { "db" }
      let(:linked_to_service) do
        {
          from_service: service_uuid,
          name: linked_service_name,
          to_service: linked_service_uuid
        }
      end

      before do
        allow(docker_cloud_service).to receive(:linked_to_service).and_return([linked_to_service])
      end

      it "returns a list of KumoDockerCloud::Service object that are linked to from this service" do
        links = subject.links
        expect(links.first).to have_attributes(name: linked_service_name)
        expect(links.size).to eq(1)
      end

      it "returns an empty array if there are no links" do
        allow(docker_cloud_service).to receive(:linked_to_service).and_return([])
        expect(subject.links).to eq([])
      end
    end

    describe "#set_link" do
      let(:linked_service_uuid) { "i_am_the_db" }
      let(:linked_service_name) { "db" }
      let(:linked_to_service) do
        {
          to_service: "api/v1/#{linked_service_uuid}",
          name: linked_service_name,
          from_service: "api/v1/#{service_uuid}"
        }
      end
      let(:linked_service) { KumoDockerCloud::Service.new('stack_name', linked_service_name) }
      let(:this_service) { double(:this_service, uuid: service_uuid, resource_uri: "api/v1/#{service_uuid}") }
      let(:linked_service) { double(:linked_service, uuid: linked_service_uuid, resource_uri: "api/v1/#{linked_service_uuid}", name: linked_service_name) }

      before do
        allow(docker_cloud_api).to receive(:service_by_stack_and_service_name).with('stack_name', 'service_name').and_return(this_service)
        allow(docker_cloud_api).to receive(:service_by_stack_and_service_name).with('stack_name', linked_service_name).and_return(linked_service)
      end

      it "updates the link attribute" do
        expect(docker_cloud_services_api).to receive(:update).with(service_uuid, { linked_to_service: [linked_to_service] })

        subject.set_link(linked_service)
      end
    end

    describe "#stop" do
      it "sends a request to stop the service" do
        expect(docker_cloud_services_api).to receive(:stop).with(service_uuid)

        subject.stop
      end
    end
  end
end
