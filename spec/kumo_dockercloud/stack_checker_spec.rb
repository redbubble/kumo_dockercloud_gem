describe KumoDockerCloud::StackChecker do

  let(:stack) { double(:stack_api, name: 'stack' )}
  let(:service) { double(:service, name: 'redbubble', state: 'Running') }
  let(:services) { [service]}
  let(:failed_services) { double(:service_api, name: 'redbubble', state: 'Stopped')}
  let(:docker_cloud_api) { instance_double(KumoDockerCloud::DockerCloudApi)}
  let(:service_checker) { instance_double(KumoDockerCloud::ServiceChecker, verify: nil)}
  let(:default_service_check) { [double(:default_check)] }
  let(:specific_service_check) { { "redbubble" => [double(:specific_check)] } }

  subject { described_class.new.verify(stack) }

  before do
    allow(KumoDockerCloud::DockerCloudApi).to receive(:new).and_return(docker_cloud_api)
    allow(docker_cloud_api).to receive(:services_by_stack_name).with(stack.name).and_return(services)
  end

  describe '#verify' do

    before do
        allow(KumoDockerCloud::ServiceChecker).to receive(:new).and_return(service_checker)
    end

    context 'single service' do
      context 'without passing services checks' do
        before { allow_any_instance_of(KumoDockerCloud::StackChecker).to receive(:default_check).and_return(default_service_check) }
        it 'returns true when verify successful' do
          expect(subject).to be true
        end

        it 'uses default check' do

          expect(KumoDockerCloud::ServiceChecker).to receive(:new).with(default_service_check, 300)
          subject
        end


        it 'uses user specify timeout value' do
          user_timeout = 1
          allow_any_instance_of(KumoDockerCloud::StackChecker).to receive(:default_check).and_return(default_service_check)
          expect(KumoDockerCloud::ServiceChecker).to receive(:new).with(default_service_check,user_timeout)
          described_class.new({}, nil, user_timeout).verify(stack)
        end

        it 'raise StackCheckError when verify unsuccessful' do
          allow(service_checker).to receive(:verify).with(service).and_raise KumoDockerCloud::ServiceDeployError
          allow(docker_cloud_api).to receive(:services_by_stack_name).with(stack.name).and_return(services)
          expect {subject}.to raise_error(KumoDockerCloud::StackCheckError, "The stack is not in the expected state." )
        end
      end

      context 'with user specifiy default services checks' do
        it 'uses user specify default check' do
          user_specify_default_check = double(:user_specify_default_check)
          expect(KumoDockerCloud::ServiceChecker).to receive(:new).with(user_specify_default_check,300)
          described_class.new({}, user_specify_default_check).verify(stack)
        end
      end

      context 'with specific services checks passing in' do
        subject { described_class.new(specific_service_check).verify(stack) }

        it 'returns true when verify successful' do
          expect(subject).to be true
        end

        it 'raise StackCheckError when verify unsuccessful' do
          allow(service_checker).to receive(:verify).with(service).and_raise KumoDockerCloud::ServiceDeployError
          allow(docker_cloud_api).to receive(:services_by_stack_name).with(stack.name).and_return(services)
          expect {subject}.to raise_error(KumoDockerCloud::StackCheckError, "The stack is not in the expected state." )
        end

        it 'uses specific check' do
          expect(KumoDockerCloud::ServiceChecker).to receive(:new).with(specific_service_check[service.name], 300)
          subject
        end
      end
    end

    context 'multiple services' do
      let(:services) {[double(:redbubble_service, name: 'redbubble', state: 'Running'), double(:nginx_service, name: 'nginx', state: 'Running')]}
      let(:redbubble_check) { double(:redbubble_check) }
      let(:nginx_check) { double(:nginx_check) }
      let(:specific_service_check) { { "redbubble" => [redbubble_check], "nginx" => [nginx_check] } }
      let(:single_override_service_check) { { "redbubble" => [redbubble_check] } }

      subject { described_class.new(specific_service_check).verify(stack) }

      context 'default checks' do
        before { allow_any_instance_of(KumoDockerCloud::StackChecker).to receive(:default_check).and_return(default_service_check)  }

        it 'does the correct checking for each service' do
          expect(KumoDockerCloud::ServiceChecker).to receive(:new).with([redbubble_check], 300)
          expect(KumoDockerCloud::ServiceChecker).to receive(:new).with([nginx_check], 300)
          subject
        end

        it 'uses default checking if one of the service check is not provided' do

          expect(KumoDockerCloud::ServiceChecker).to receive(:new).with([redbubble_check], 300)
          expect(KumoDockerCloud::ServiceChecker).to receive(:new).with(default_service_check, 300)
          described_class.new(single_override_service_check).verify(stack)
        end
      end

      context 'passing common checks' do
        let(:specific_service_check) { { "redbubble" => [redbubble_check] } }
        let(:common_service_checks) { [double(:common_service_check)] }
        subject { described_class.new(specific_service_check, common_service_checks).verify(stack) }

        it 'overrides the default check with the common checks' do
          expect(KumoDockerCloud::ServiceChecker).to receive(:new).with([redbubble_check], 300)
          expect(KumoDockerCloud::ServiceChecker).to receive(:new).with(common_service_checks, 300)
          subject
        end
      end
    end
  end
end
