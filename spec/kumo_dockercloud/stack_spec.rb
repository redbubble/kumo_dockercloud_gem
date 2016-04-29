require 'spec_helper'

describe KumoDockerCloud::Stack do
  let(:service_api) { instance_double(DockerCloud::ServiceAPI) }
  let(:uuid) { 'foo' }
  let(:service_name) { 'test_service' }
  let(:app_name) { 'test_app' }
  let(:environment_name) { 'environment' }
  let(:app_version) { '1' }
  let(:client) { instance_double(DockerCloud::Client, stacks: stacks, services: service_api) }
  let(:stacks) { double('stacks', all: [stack]) }
  let(:stack_name) { "#{app_name}-#{environment_name}" }
  let(:stack) { instance_double(DockerCloud::Stack, name: stack_name) }
  let(:service) { instance_double(KumoDockerCloud::Service, uuid: uuid) }
  let(:check_timeout) { 300 }

  before do
    allow(::DockerCloud::Client).to receive(:new).and_return(client)
    allow(KumoDockerCloud::Service).to receive(:new).with(stack_name, service_name).and_return(service)
    allow(service).to receive(:deploy).with("test_version")
    allow(service).to receive(:check).with([], 300)
  end

  describe '#deploy' do
    subject { described_class.new(app_name, environment_name) }

    it 'complains if passed a nil service name' do
      expect { subject.deploy(nil, 1) }.to raise_error(KumoDockerCloud::Error, 'Service name cannot be nil')
    end

    it 'complains if passed an empty service name' do
      expect { subject.deploy("", 1) }.to raise_error(KumoDockerCloud::Error, 'Service name cannot be empty')
    end

    it 'complains if passed a nil version' do
      expect { subject.deploy("test_service", nil) }.to raise_error(KumoDockerCloud::Error, 'Version cannot be nil')
    end

    it 'complains if passed an empty version' do
      expect { subject.deploy("test_service", "") }.to raise_error(KumoDockerCloud::Error, 'Version cannot be empty')
    end

    it 'deploys the version of my service' do
      expect(service).to receive(:deploy).with("test_version")
      subject.deploy('test_service', 'test_version')
    end

    it 'passes any checks to the checker' do
      checks = ["check1", "check2"]
      allow(service).to receive(:deploy).with("test_version")
      expect(service).to receive(:check).with(checks, check_timeout)
      subject.deploy('test_service', 'test_version', checks)
    end

    it 'passes any specific timeout to the checker' do
      checks = ["check1", "check2"]
      shortened_timeout = 10
      allow(service).to receive(:deploy).with("test_version")
      expect(service).to receive(:check).with(checks, shortened_timeout)
      subject.deploy('test_service', 'test_version', checks, shortened_timeout)
    end

  end

  describe '#deploy_blue_green' do
    let(:service_a_uuid) { 'service_a_uuid' }
    let(:service_a) { instance_double(KumoDockerCloud::Service, :service_a, uuid: uuid, name: "service-a") }
    let(:service_b_uuid) { 'service_b_uuid' }
    let(:service_b) { instance_double(KumoDockerCloud::Service, :service_b, uuid: uuid, name: "service-b") }
    let(:nginx) { instance_double(KumoDockerCloud::Service, uuid: "nginx_uuid") }
    let(:version) { "1" }
    let(:deployment_checks) { [] }
    let(:links) { [service_a] }
    let(:check_timeout) { 120 }
    let(:deploy_options) do
      {
        service_names: ["service-a", "service-b"],
        version: version,
        checks: deployment_checks,
        check_timeout: check_timeout,
        switching_service_name: "nginx"
      }
    end

    subject { described_class.new(app_name, environment_name).deploy_blue_green(deploy_options) }

    before do
      allow(KumoDockerCloud::Service).to receive(:new)
        .with(stack_name, "service-a")
        .and_return(service_a)

      allow(KumoDockerCloud::Service).to receive(:new)
        .with(stack_name, "service-b")
        .and_return(service_b)

      allow(KumoDockerCloud::Service).to receive(:new)
        .with(stack_name, "nginx")
        .and_return(nginx)

      allow(nginx).to receive(:links).and_return(links)
      allow(nginx).to receive(:set_link).with(service_b)

      allow(service_a).to receive(:stop)

      allow(service_b).to receive(:deploy).with(version)
      allow(service_b).to receive(:check).with(deployment_checks, check_timeout)
    end

    context 'when parameters are missing' do
      it 'blow up when version is missing' do
        deploy_options.delete(:version)
        expect{ subject }.to raise_error(KumoDockerCloud::Error, "Version cannot be nil")
      end

      it 'blow up when service_names are missing' do
        deploy_options.delete(:service_names)
        expect{ subject }.to raise_error(KumoDockerCloud::Error, "Service names cannot be nil")
      end

      it 'blow up when switching_service_name is missing' do
        deploy_options.delete(:switching_service_name)
        expect{ subject }.to raise_error(KumoDockerCloud::Error, "Switching service name cannot be nil")
      end
    end

    it 'deploys to the blue service only' do
      expect(service_b).to receive(:deploy).with(version)
      expect(service_b).to receive(:check).with(deployment_checks, check_timeout)
      expect(service_a).to_not receive(:deploy)
      subject
    end

    it 'switches over to the blue service on a successful deployment' do
      expect(nginx).to receive(:set_link).with(service_b)
      subject
    end

    it 'shuts down the previously green service' do
      expect(service_a).to receive(:stop)
      subject
    end
  end
end
