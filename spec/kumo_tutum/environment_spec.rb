require 'kumo_tutum/environment'
require 'kumo_tutum/environment_config'

describe KumoTutum::Environment do
  let(:env_vars) { {'KEY' => 'VALUE'} }
  let(:app_name) { 'application-stack-name' }
  let(:config) { KumoTutum::EnvironmentConfig.new(app_name: app_name, env_name: 'test', config_path: 'a path') }

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


  subject(:env) { described_class.new(name: 'test', env_vars: env_vars, app_name: app_name, config_path: 'a path', stack_template_path: File.join(__dir__, '../fixtures/stack.yml.erb')) }

  before do
    allow(KumoTutum::EnvironmentConfig).to receive(:new).and_return(config)
    allow(KumoTutum::StackFile).to receive(:create_from_template).and_return(stack_file)
  end

  describe "#apply" do
    subject { env.apply }

    let(:full_stack_name) { "#{app_name}-test" }

    before do
      allow(config).to receive(:image_tag).and_return('latest')
      allow(env).to receive(:evaluate_command).and_return app_name
      allow(env).to receive(:run_command)
      tutum_api = double("TutumApi", stack_by_name: {"#{full_stack_name}": 'stack stuff'})
      allow(KumoTutum::TutumApi).to receive(:new).and_return tutum_api
      allow_any_instance_of(KumoTutum::StateValidator).to receive(:wait_for_state)
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

    it "makes sure it waits until it's running" do
      expect(KumoTutum::StateValidator).to receive(:new).exactly(3).times.and_return(double(KumoTutum::StateValidator, wait_for_state: nil))

      subject
    end
  end
end
