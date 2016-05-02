describe KumoDockerCloud::Stack do
  let(:stack) { described_class.new(app_name, environment_name) }
  let(:app_name) { 'test_app' }
  let(:environment_name) { 'environment' }
  let(:stack_name) { stack.stack_name }

  describe '#deploy' do
    let(:service_name) { 'test_service' }
    let(:version) { '1' }
    let(:check) { instance_double(KumoDockerCloud::ServiceCheck, verify: nil) }
    let(:service) { instance_double(KumoDockerCloud::Service) }

    before do
      allow(KumoDockerCloud::Service).to receive(:new).with(stack_name, service_name).and_return(service)
      allow(service).to receive(:deploy).with(version)
    end

    subject { stack.deploy(service_name, version) }

    it 'deploys the version of my service' do
      expect(service).to receive(:deploy).with(version)
      subject
    end

    context "validation" do
      context "nil name" do
        let(:service_name) { nil }

        it "complains" do
          expect { subject }.to raise_error(KumoDockerCloud::Error, 'Service name cannot be nil')
        end
      end

      context "empty name" do
        let(:service_name) { "" }

        it "complains" do
          expect { subject }.to raise_error(KumoDockerCloud::Error, 'Service name cannot be empty')
        end
      end

      context "nil version" do
        let(:version) { nil }

        it "complains" do
          expect { subject }.to raise_error(KumoDockerCloud::Error, 'Version cannot be nil')
        end
      end

      context "empty version" do
        let(:version) { "" }

        it "complains" do
          expect { subject }.to raise_error(KumoDockerCloud::Error, 'Version cannot be empty')
        end
      end
    end

    context "with a check supplied" do
      subject { stack.deploy(service_name, version, check) }

      it 'uses the supplied service check' do
        expect(check).to receive(:verify).with(service)
        subject
      end
    end
  end

  describe '#deploy_blue_green' do
    let(:service_api) { instance_double(DockerCloud::ServiceAPI) }
    let(:uuid) { 'foo' }
    let(:client) { instance_double(DockerCloud::Client, stacks: stacks, services: service_api) }
    let(:stacks) { double('stacks', all: [stack]) }
    let(:service_name) { 'test_service' }
    let(:version) { '1' }
    let(:check) { instance_double(KumoDockerCloud::ServiceCheck, verify: nil) }
    let(:service) { instance_double(KumoDockerCloud::Service) }


    let(:service_a_uuid) { 'service_a_uuid' }
    let(:service_a) { instance_double(KumoDockerCloud::Service, :service_a, uuid: uuid, name: "service-a") }
    let(:service_b_uuid) { 'service_b_uuid' }
    let(:service_b) { instance_double(KumoDockerCloud::Service, :service_b, uuid: uuid, name: "service-b") }
    let(:nginx) { instance_double(KumoDockerCloud::Service, uuid: "nginx_uuid") }
    let(:version) { "1" }
    let(:links) { [service_a] }
    let(:switching_service_link_name) { "app" }
    let(:deploy_options) do
      {
        service_names: ["service-a", "service-b"],
        version: version,
        check: check,
        switching_service_name: "nginx",
        switching_service_link_name: switching_service_link_name
      }
    end

    subject { described_class.new(app_name, environment_name).deploy_blue_green(deploy_options) }

    before do
      allow(::DockerCloud::Client).to receive(:new).and_return(client)
      allow(KumoDockerCloud::Service).to receive(:new).with(stack_name, service_name).and_return(service)
      allow(service).to receive(:deploy).with(version)

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
      allow(nginx).to receive(:set_link).with(service_b, switching_service_link_name)

      allow(service_a).to receive(:stop)

      allow(service_b).to receive(:deploy).with(version)
    end

    context 'when parameters are missing' do
      it 'blows up when version is missing' do
        deploy_options.delete(:version)
        expect{ subject }.to raise_error(KumoDockerCloud::Error, "Version cannot be nil")
      end

      it 'blows up when service_names are missing' do
        deploy_options.delete(:service_names)
        expect{ subject }.to raise_error(KumoDockerCloud::Error, "Service names cannot be nil")
      end

      it 'blows up when switching_service_name is missing' do
        deploy_options.delete(:switching_service_name)
        expect{ subject }.to raise_error(KumoDockerCloud::Error, "Switching service name cannot be nil")
      end

      it 'blows up when switching_service_link_name is missing' do
        deploy_options.delete(:switching_service_link_name)
        expect{ subject }.to raise_error(KumoDockerCloud::Error, "Switching service link name cannot be nil")
      end
    end

    it 'deploys to the blue service only' do
      expect(service_b).to receive(:deploy).with(version)
      expect(check).to receive(:verify).with(service_b)
      expect(service_a).to_not receive(:deploy)
      subject
    end

    it 'switches over to the blue service on a successful deployment' do
      expect(nginx).to receive(:set_link).with(service_b, switching_service_link_name)
      subject
    end

    it 'shuts down the previously green service' do
      expect(service_a).to receive(:stop)
      subject
    end
  end
end
