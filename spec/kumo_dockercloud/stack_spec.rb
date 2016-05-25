describe KumoDockerCloud::Stack do
  let(:stack) { described_class.new(app_name, environment_name) }
  let(:app_name) { 'test_app' }
  let(:environment_name) { 'environment' }
  let(:stack_name) { stack.stack_name }

  describe '#deploy' do
    let(:service_name) { 'test_service' }
    let(:version) { '1' }
    let(:checker) { instance_double(KumoDockerCloud::ServiceChecker, verify: nil) }
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

    context "with a checker supplied" do
      subject { stack.deploy(service_name, version, checker) }

      it 'uses the supplied service checker' do
        expect(checker).to receive(:verify).with(service)
        subject
      end
    end
  end

  describe '#deploy_blue_green' do
    let(:service_name) { 'test_service' }
    let(:version) { '1' }
    let(:checker) { instance_double(KumoDockerCloud::ServiceChecker, verify: nil) }

    let(:active_service) { instance_double(KumoDockerCloud::Service, :active_service, name: "service-a", stop: nil) }
    let(:inactive_service) { instance_double(KumoDockerCloud::Service, :inactive_service, name: "service-b", deploy: nil) }
    let(:service_link) { { name: switching_service_internal_link_name, to_service: linked_service_uri} }
    let(:linked_service_uri) { "active_uri" }
    let(:switching_service) { instance_double(KumoDockerCloud::Service, links: [service_link], set_link: nil) }
    let(:switching_service_internal_link_name) { "app" }
    let(:deploy_options) do
      {
        service_names: [active_service.name, inactive_service.name],
        version: version,
        checker: checker,
        switching_service_name: "switcher"
      }
    end

    subject { described_class.new(app_name, environment_name).deploy_blue_green(deploy_options) }

    before do
      allow(KumoDockerCloud::Service).to receive(:service_by_resource_uri).with(linked_service_uri).and_return(active_service)

      allow(KumoDockerCloud::Service).to receive(:new)
        .with(stack_name, active_service.name)
        .and_return(active_service)

      allow(KumoDockerCloud::Service).to receive(:new)
        .with(stack_name, inactive_service.name)
        .and_return(inactive_service)

      allow(KumoDockerCloud::Service).to receive(:new)
        .with(stack_name, deploy_options[:switching_service_name])
        .and_return(switching_service)
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
    end

    it 'deploys to the blue service only' do
      expect(inactive_service).to receive(:deploy).with(version)
      expect(checker).to receive(:verify).with(inactive_service)
      expect(active_service).to_not receive(:deploy)
      subject
    end

    it 'switches over to the blue service on a successful deployment' do
      expect(switching_service).to receive(:set_link).with(inactive_service, switching_service_internal_link_name)
      subject
    end

    it 'shuts down the previously green service' do
      expect(active_service).to receive(:stop)
      subject
    end
  end

  describe '#services' do
    subject { stack.services }
    let(:docker_cloud_services) { [double(:docker_cloud_service, name: 'redbubble')]}
    let(:redbubble_service) { instance_double(KumoDockerCloud::Service, :service)}
    let(:docker_cloud_api) { double("DockerCloudApi", services_by_stack_name: docker_cloud_services)}
    before do
      allow(KumoDockerCloud::DockerCloudApi).to receive(:new).and_return docker_cloud_api
      allow(KumoDockerCloud::Service).to receive(:new).with(stack_name, 'redbubble').and_return(redbubble_service)
    end

    it 'returns the correct type of services' do
      expect(subject).to eq([redbubble_service])
    end
  end
end
