require 'spec_helper'
require 'httpi'

describe KumoDockerCloud::Service do
  let(:service_image) { "repository/docker_image_name:version" }
  let(:service_uuid) { "i_am_a_unique_snowflower" }
  let(:docker_cloud_service_api) { double(:services_api, uuid: service_uuid, image_name: service_image, containers: []) }
  let(:docker_cloud_api) { instance_double(KumoDockerCloud::DockerCloudApi, services: docker_cloud_service_api)}

  subject { described_class.new('stack_name', 'service_name') }

  before do
    allow(KumoDockerCloud::DockerCloudApi).to receive(:new).and_return(docker_cloud_api)

    allow(docker_cloud_api).to receive(:service_by_stack_and_service_name).with('stack_name', 'service_name').and_return(docker_cloud_service_api)
  end

  describe '#deploy' do
    it 'runs the actual update and redeploy methods' do
      expect(docker_cloud_service_api).to receive(:update).with(service_uuid, { image: service_image })
      expect(docker_cloud_service_api).to receive(:redeploy).with(service_uuid)
      subject.deploy('version')
    end

    it 'raises an appropriate exception when there is an error during image update' do
      expect(docker_cloud_service_api).to receive(:update).and_raise(RestClient::InternalServerError)
      expect { subject.deploy('version') }.to raise_error(KumoDockerCloud::ServiceDeployError, "Something went wrong during service update on Docker Cloud's end")
    end

    it 'raises an appropriate exception when there is an error during redployment' do
      allow(docker_cloud_service_api).to receive(:update).with(service_uuid, { image: service_image })
      expect(docker_cloud_service_api).to receive(:redeploy).and_raise(RestClient::InternalServerError)
      expect { subject.deploy('version') }.to raise_error(KumoDockerCloud::ServiceDeployError, "Something went wrong during service update on Docker Cloud's end")
    end
  end

  describe '#check' do
    let(:http_lib) { double('http_lib') }
    let(:container_status_check) {lambda { |container| container.state == 'Running' }}
    let(:endpoint_check) {lambda do |container|
      url = "#{container.container_ports.first[:endpoint_uri]}/site_status"
      response = http_lib.get(url)
      response == 200
    end}
    let(:checks) {[container_status_check, endpoint_check]}
    let(:check_timeout) { 300 }


    def containers(overrides = {})
      container_opts = {
        updatable_state: "Starting"
      }.merge(overrides)

      [
        double(:whale1, state: container_opts[:updatable_state], container_ports: [{endpoint_uri: "http://whale1.test"}]),
        double(:whale2, state: "Running", container_ports: [{endpoint_uri: "http://whale2.test"}]),
      ]
    end

    before do
      allow(http_lib).to receive(:get).with("http://whale1.test/site_status").and_return(200)
      allow(http_lib).to receive(:get).with("http://whale2.test/site_status").and_return("timeout", "timeout", 200)
      allow(docker_cloud_service_api).to receive(:reload)
    end

    it 'resolves to true if all the checks eventually pass' do
      allow(subject).to receive(:sleep).and_return(nil)
      allow(docker_cloud_service_api).to receive(:containers).and_return(containers(), containers(updatable_state: "Running"))
      expect(subject.check(checks, check_timeout)).to eq(true)
    end


    it 'raises an error if any check fails to pass within the timeout period' do
      short_timeout = 2
      allow(docker_cloud_service_api).to receive(:containers).and_return(containers(), containers())
      expect { subject.check(checks, short_timeout) }.to raise_error(KumoDockerCloud::ServiceDeployError, "One or more checks failed to pass within the timeout")
    end

    it 'reloads the service object once for every check run' do
      allow(subject).to receive(:sleep).and_return(nil)
      allow(docker_cloud_service_api).to receive(:containers).and_return(containers(), containers(updatable_state: "Running"))
      expect(docker_cloud_service_api).to receive(:reload).exactly(3).times
      subject.check(checks, check_timeout)
    end
  end
end
