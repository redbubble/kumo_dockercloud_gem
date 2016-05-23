describe KumoDockerCloud::Environment do
  let(:env_vars) { {app_name => {'KEY' => 'VALUE'}} }
  let(:app_name) { 'application-stack-name' }
  let(:config) { KumoDockerCloud::EnvironmentConfig.new(app_name: app_name, env_name: 'test', config_path: 'a path') }

  let(:stack_file) {
    {
      'application-stack-name' => {
        image: 'a-thing',
        environment: {
          TEST_ENV: 'FAKE',
          MORE: 'ANOTHER',
          KEY: 'VALUE'
        }
      }
    }
  }
  let(:full_stack_name) { "#{app_name}-test" }
  let(:confirmation_timeout) { 0.5 }
  let(:stack_template_path) { File.join(__dir__, '../fixtures/stack.yml.erb') }

  let(:params) { {name: 'test', env_vars: env_vars, app_name: app_name, config_path: 'a path', stack_template_path: stack_template_path, confirmation_timeout: confirmation_timeout} }

  subject(:env) { described_class.new(params) }

  before do
    allow(KumoDockerCloud::EnvironmentConfig).to receive(:new).and_return(config)
    allow(KumoDockerCloud::StackFile).to receive(:create_from_template).and_return(stack_file)
  end

  describe "#apply" do
    subject { env.apply }
    let(:stack) { {"#{full_stack_name}" => 'stack stuff'} }
    before do
      allow(config).to receive(:image_tag).and_return('latest')
      allow(env).to receive(:evaluate_command).and_return app_name
      allow(env).to receive(:run_command)
      docker_cloud_api = double("DockerCloudApi", stack_by_name: stack)
      allow(KumoDockerCloud::DockerCloudApi).to receive(:new).and_return docker_cloud_api
      allow_any_instance_of(KumoDockerCloud::StateValidator).to receive(:wait_for_state)
      allow_any_instance_of(KumoDockerCloud::StackChecker).to receive(:verify).with(stack).and_return true
    end

    it "writes a stack file" do
      expect_any_instance_of(Tempfile).to receive(:write).with(stack_file.to_yaml)

      subject
    end

    it 'runs the stack command' do
      expect(env).to receive(:run_command).with(%r{^docker-cloud stack create -f .* -n #{full_stack_name}$})

      subject
    end

    it 'runs the redeploy command' do
      expect(env).to receive(:run_command).with("docker-cloud stack redeploy #{full_stack_name}")

      subject
    end

    it 'uses the StackFile class' do
      expect(KumoDockerCloud::StackFile).to receive(:create_from_template).with(File.read(stack_template_path), config, env_vars)

      subject
    end

    context 'with specific service checks passed in' do

      let(:service_checks) { instance_double(KumoDockerCloud::ServiceChecker) }
      let(:checks) { { 'db_migration' => service_checks } }
      let(:stack_checker) { instance_double(KumoDockerCloud::StackChecker, :stack_checker, verify: true ) }
      subject { env.apply(checks) }

      it 'returns true when status check is successful' do
        expect(subject).to be true
      end

      it 'raise and stack_apply_exception when status check is not successful' do

        allow_any_instance_of(KumoDockerCloud::StackChecker).to receive(:verify).with(stack).and_raise(KumoDockerCloud::StackCheckError)
        expect{subject}.to raise_error(KumoDockerCloud::EnvironmentApplyError, "The stack is not in the expected state." )
      end

      context 'with specific timeout passed in' do
        let(:timeout) { 10 }

        subject { env.apply(checks, nil, timeout) }
        it 'uses the user passed in timeout' do
          expect(KumoDockerCloud::StackChecker).to receive(:new).with(checks, nil, timeout).and_return(stack_checker)
          subject
        end
      end

      context 'with specific common checks passed in' do
        let(:common_checks) { [instance_double(KumoDockerCloud::ServiceChecker)] }
        subject { env.apply(checks, common_checks) }
        it 'uses the user specified common checks' do
          expect(KumoDockerCloud::StackChecker).to receive(:new).with(checks, common_checks, 300).and_return(stack_checker)
          subject
        end
      end
    end

    context 'without specific service checking passed in' do
      it 'returns true when status check is successful' do
        expect(subject).to be true
      end

      it 'raises a stack_apply_exception when status check is not successful' do
        allow_any_instance_of(KumoDockerCloud::StackChecker).to receive(:verify).with(stack).and_raise(KumoDockerCloud::StackCheckError)
        expect{subject}.to raise_error(KumoDockerCloud::EnvironmentApplyError, "The stack is not in the expected state." )
      end
    end
  end



  describe "#destroy" do
    subject { env.destroy }
    before do
      allow(KumoDockerCloud::ConsoleJockey).to receive(:flash_message).with("Warning! You are about to delete the Docker Cloud Stack #{full_stack_name}, enter 'yes' to continue.")
    end

    it "notifies the user of what it is about to delete" do
      expect(KumoDockerCloud::ConsoleJockey).to receive(:flash_message).with("Warning! You are about to delete the Docker Cloud Stack #{full_stack_name}, enter 'yes' to continue.")
      subject
    end

    it "does delete the stack if the user confirms" do
      expect(KumoDockerCloud::ConsoleJockey).to receive(:get_confirmation).with(confirmation_timeout).and_return(true)
      expect(env).to receive(:run_command).with("docker-cloud stack terminate --sync #{full_stack_name}")
      subject
    end

    it "does not delete the stack if the the user refuses confirmation" do
      expect(KumoDockerCloud::ConsoleJockey).to receive(:get_confirmation).with(confirmation_timeout).and_return(false)
      subject
    end

  end
end
