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
    let(:dockercloud_api) { instance_double(KumoDockerCloud::DockerCloudApi) }

    before do
      allow(KumoDockerCloud::DockerCloudApi).to receive(:new).with({}).and_return(dockercloud_api)
      allow(KumoDockerCloud::Service).to receive(:new).with(stack_name, service_name, dockercloud_api).and_return(service)
      allow(service).to receive(:deploy).with(version)
    end

    subject { stack.deploy(service_name, version) }

    context 'with encrypted credentials' do
      let(:encrypted_creds) { { encrypted_dockercloud_user: "[ENC,#{encrypted_user}", encrypted_dockercloud_apikey: "[ENC,#{encrypted_apikey}" } }
      let(:stack_with_encrypted_creds) { described_class.new(app_name, environment_name, encrypted_creds) }
      let(:credentials_decrypter) { instance_double(KumoDockerCloud::CredentialsDecrypter) }
      let(:encrypted_user) { 'encrypted_user' }
      let(:encrypted_apikey) { 'encrypted_apikey' }
      let(:plaintext_user) { 'plaintext_user' }
      let(:plaintext_apikey) { 'plaintext_apikey' }
      let(:decrypted_creds) { { username: plaintext_user, api_key: plaintext_apikey } }

      subject { stack_with_encrypted_creds.deploy(service_name, version) }

      before do
        allow(KumoDockerCloud::CredentialsDecrypter).to receive(:new).and_return(credentials_decrypter)
        allow(credentials_decrypter).to receive(:decrypt).with(encrypted_creds).and_return(decrypted_creds)
        allow(KumoDockerCloud::DockerCloudApi).to receive(:new).with(decrypted_creds).and_return(dockercloud_api)
      end

      it 'decrypts the credentials and uses them to authenticate with docker cloud' do
        expect(KumoDockerCloud::Service).to receive(:new).with(stack_name, service_name, dockercloud_api).and_return(service)

        subject
      end
    end

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
    subject { stack.deploy_blue_green(service_names, version, checker) }
    let(:checker) { instance_double(KumoDockerCloud::ServiceChecker, :service_checker, verify: true) }
    let(:service_names) { ['service-a', 'service-b'] }
    let(:version) { 1 }
    let(:service_a) { instance_double(KumoDockerCloud::Service, :service_a, state: 'Running', deploy: nil, name: 'service_a') }
    let(:service_b) { instance_double(KumoDockerCloud::Service, :service_b, state: 'Running', deploy: nil, name: 'service_b') }
    let(:haproxy) { instance_double(KumoDockerCloud::HaproxyService, :haproxy_svc, disable_service: nil, enable_service: nil) }
    let(:dockercloud_api) { instance_double(KumoDockerCloud::DockerCloudApi) }

    before do
      allow(KumoDockerCloud::DockerCloudApi).to receive(:new).with({}).and_return(dockercloud_api)
      allow(KumoDockerCloud::Service).to receive(:new).with(stack_name, 'service-a', dockercloud_api).and_return(service_a)
      allow(KumoDockerCloud::Service).to receive(:new).with(stack_name, 'service-b', dockercloud_api).and_return(service_b)
      allow(KumoDockerCloud::HaproxyService).to receive(:new).with(stack_name, dockercloud_api).and_return(haproxy)
      allow(KumoDockerCloud::ConsoleJockey).to receive(:write_line)
    end

    it 'deploys to each service when both are active' do
      expect(haproxy).to receive(:disable_service).with(service_a)
      expect(haproxy).to receive(:disable_service).with(service_b)
      expect(service_a).to receive(:deploy).with(version)
      expect(service_b).to receive(:deploy).with(version)
      subject
    end

    it 'deploys to the stopped service first when one is inactive' do
      allow(service_b).to receive(:state).and_return('Stopped')

      expect(haproxy).to_not receive(:disable_service).with(service_b)
      expect(service_b).to receive(:deploy).with(version).ordered
      expect(haproxy).to receive(:disable_service).with(service_a).ordered
      expect(service_a).to receive(:deploy).with(version).ordered
      subject
    end

    it 'runs the check on each service' do
      expect(checker).to receive(:verify).with(service_a)
      expect(checker).to receive(:verify).with(service_b)
      subject
    end

    it 're-enables each service in haproxy' do
      expect(haproxy).to receive(:enable_service).with(service_a)
      expect(haproxy).to receive(:enable_service).with(service_b)
      subject
    end

    it 'cancels deployment if the first deploy fails' do
      allow(checker).to receive(:verify).with(service_a).and_raise(KumoDockerCloud::ServiceDeployError)
      expect(service_b).to_not receive(:deploy)
      expect { subject }.to raise_error(KumoDockerCloud::ServiceDeployError)
    end

    it 'raises an error if any attempt to place a service into maintainance mode fails' do
      expect(haproxy).to receive(:disable_service).with(service_a).and_raise(KumoDockerCloud::HAProxyStateError, 'Something broke!')
      expect { subject }.to raise_error(KumoDockerCloud::ServiceDeployError)
    end

    it 'attempts to place a service into maintainance mode if deployment fails because HAProxy will take it out of maintainance mode on deploy' do
      expect(haproxy).to receive(:disable_service).with(service_a).twice
      allow(checker).to receive(:verify).with(service_a).and_raise(KumoDockerCloud::ServiceDeployError)
      expect { subject }.to raise_error(KumoDockerCloud::ServiceDeployError)
    end

    context 'with encrypted credentials' do
      let(:encrypted_creds) { { encrypted_dockercloud_user: "[ENC,#{encrypted_user}", encrypted_dockercloud_apikey: "[ENC,#{encrypted_apikey}" } }
      let(:stack_with_encrypted_creds) { described_class.new(app_name, environment_name, encrypted_creds) }
      let(:credentials_decrypter) { instance_double(KumoDockerCloud::CredentialsDecrypter) }
      let(:encrypted_user) { 'encrypted_user' }
      let(:encrypted_apikey) { 'encrypted_apikey' }
      let(:plaintext_user) { 'plaintext_user' }
      let(:plaintext_apikey) { 'plaintext_apikey' }
      let(:decrypted_creds) { { username: plaintext_user, api_key: plaintext_apikey } }

      subject { stack_with_encrypted_creds.deploy_blue_green(service_names, version, checker) }

      before do
        allow(KumoDockerCloud::CredentialsDecrypter).to receive(:new).and_return(credentials_decrypter)
        allow(credentials_decrypter).to receive(:decrypt).with(encrypted_creds).and_return(decrypted_creds)
        allow(KumoDockerCloud::DockerCloudApi).to receive(:new).with(decrypted_creds).and_return(dockercloud_api)
      end

      it 'decrypts the credentials and uses them to authenticate with docker cloud' do
        expect(KumoDockerCloud::Service).to receive(:new).with(stack_name, 'service-a', dockercloud_api).and_return(service_a)
        expect(KumoDockerCloud::Service).to receive(:new).with(stack_name, 'service-b', dockercloud_api).and_return(service_b)
        expect(KumoDockerCloud::HaproxyService).to receive(:new).with(stack_name, dockercloud_api).and_return(haproxy)

        subject
      end
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

  describe '#exists' do
    subject { stack.exists? }
    let(:docker_cloud_api) { instance_double(KumoDockerCloud::DockerCloudApi, stack_by_name: docker_cloud_stack) }
    before do
      allow(KumoDockerCloud::DockerCloudApi).to receive(:new).and_return docker_cloud_api
    end

    context 'when the stack exists in docker cloud' do
      let(:docker_cloud_stack) { double(:docker_cloud_stack) }
      it 'is true when the stack exists in docker cloud' do
        expect(subject).to eq(true)
      end
    end

    context 'when the stack does not exist in docker cloud' do
      let(:docker_cloud_stack) { nil }
      it 'is false when the stack does not exist in docker cloud' do
        expect(subject).to eq(false)
      end
    end
  end
end
