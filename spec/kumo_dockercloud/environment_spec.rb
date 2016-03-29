require 'kumo_dockercloud/environment'
require 'kumo_dockercloud/environment_config'

describe KumoDockerCloud::Environment do
  let(:env_vars) { {app_name => {'KEY' => 'VALUE'}} }
  let(:app_name) { 'application-stack-name' }
  let(:config) { KumoDockerCloud::EnvironmentConfig.new(app_name: app_name, env_name: 'test', config_path: 'a path') }

  let(:stack_file) {
    {
      'application-stack-name': {
        image: 'a-thing',
        environment: {
          TEST_ENV: 'FAKE',
          MORE: 'ANOTHER',
          KEY: 'VALUE'
        }
      }
    }
  }

  let(:stack_template_path) { File.join(__dir__, '../fixtures/stack.yml.erb') }

  let(:params) { {name: 'test', env_vars: env_vars, app_name: app_name, config_path: 'a path', stack_template_path: stack_template_path} }

  subject(:env) { described_class.new(params) }

  before do
    allow(KumoDockerCloud::EnvironmentConfig).to receive(:new).and_return(config)
    allow(KumoDockerCloud::StackFile).to receive(:create_from_template).and_return(stack_file)
  end

  describe "#apply" do
    subject { env.apply }

    let(:full_stack_name) { "#{app_name}-test" }

    before do
      allow(config).to receive(:image_tag).and_return('latest')
      allow(env).to receive(:evaluate_command).and_return app_name
      allow(env).to receive(:run_command)
      docker_cloud_api = double("DockerCloudApi", stack_by_name: {"#{full_stack_name}": 'stack stuff'})
      allow(KumoDockerCloud::DockerCloudApi).to receive(:new).and_return docker_cloud_api
      allow_any_instance_of(KumoDockerCloud::StateValidator).to receive(:wait_for_state)
    end

    it "writes a stack file" do
      expect_any_instance_of(Tempfile).to receive(:write).with(stack_file.to_yaml)

      subject
    end

    it 'runs the stack command' do
      expect(env).to receive(:run_command).with(%r{^tutum stack create -f .* -n #{full_stack_name}$})

      subject
    end

    it 'runs the tutum redeploy command' do
      expect(env).to receive(:run_command).with("tutum stack redeploy #{full_stack_name}")

      subject
    end

    describe "waiting for running" do

      let(:state_validator) { double(KumoDockerCloud::StateValidator, wait_for_state: nil) }

      before do
        allow(KumoDockerCloud::StateValidator).to receive(:new).exactly(3).times.and_return(state_validator)
      end

      it "makes sure it waits until it's running" do
        expect(state_validator).to receive(:wait_for_state).with(anything, 120).exactly(3).times
        subject
      end

      context "setting a different timeout value" do
        let(:params) { {name: 'test', env_vars: env_vars, app_name: app_name, config_path: 'a path', stack_template_path: stack_template_path, timeout: 240} }

        it "sends the timeout value to the StateValidator" do
          expect(state_validator).to receive(:wait_for_state).with(anything, 240).exactly(3).times
          subject
        end
      end

    end

    it 'uses the StackFile class' do
      expect(KumoDockerCloud::StackFile).to receive(:create_from_template).with(File.read(stack_template_path), config, env_vars)

      subject
    end
  end
end
