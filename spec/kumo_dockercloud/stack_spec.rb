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
end
