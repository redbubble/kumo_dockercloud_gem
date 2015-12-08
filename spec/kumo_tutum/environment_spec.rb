require 'kumo_tutum/environment'
require 'kumo_tutum/environment_config'

describe KumoTutum::Environment do
  subject(:env) { described_class.new(name: 'test', env_vars: {'KEY' => 'VALUE'}, config_path: 'a path', stack_template_path: File.join(__dir__, '../fixtures/stack.yml.erb')) }
  let(:app_name) { 'application-stack-name' }
  let(:config) { KumoTutum::EnvironmentConfig.new(app_name: app_name, env_name: 'test', config_path: 'a path') }

  let(:plain_text_secrets) do
    {
        'TEST_ENV' => 'FAKE',
        'MORE' => 'ANOTHER'
    }
  end

  before do
    allow(KumoTutum::EnvironmentConfig).to receive(:new).and_return(config)
    allow(config).to receive(:plain_text_secrets).and_return(plain_text_secrets)

  end

  describe '#configure_stack' do
    subject { env.configure_stack(stack_template) }


    let(:stack_template) do
      <<-eos
          application-stack-name:
            image: a-thing
      eos
    end

    it 'creates an EnvironmentConfig' do
      expect(KumoTutum::EnvironmentConfig).to receive(:new).with(hash_including(config_path: 'a path'))
      subject
    end

    it 'adds environment variables to stack config' do
      expect(subject).to eq(app_name => {
          'image' => 'a-thing',
          'environment' => {
              'TEST_ENV' => 'FAKE',
              'MORE' => 'ANOTHER',
              'KEY' => 'VALUE'
          }
      })
    end

    context 'with some existing environment' do
      let(:stack_template) do
        <<-eos
          application-stack-name:
            image: a-thing
            environment:
              TEST: thing
        eos
      end
      it 'should add new secrets to the environment' do
        expect(subject).to eq(app_name => {
            'image' => 'a-thing',
            'environment' => {
                'TEST' => 'thing',
                'TEST_ENV' => 'FAKE',
                'MORE' => 'ANOTHER',
                'KEY' => 'VALUE'
            }
        })
      end
    end

    context 'without any existing environment' do
      let(:stack_template) do
        <<-eos
          application-stack-name:
            image: a-thing
        eos
      end
      it 'should create the environment with secrets in it' do
        expect(subject).to eq(app_name => {
            'image' => 'a-thing',
            'environment' => {
                'TEST_ENV' => 'FAKE',
                'MORE' => 'ANOTHER',
                'KEY' => 'VALUE'
            }
        })
      end
    end
  end

  describe "#apply" do
    subject { env.apply }
    let(:stack_file_data_yaml) { double("stack_file_data_yaml") }

    let(:configured_stack_file) {
      <<-YAML
---
application-stack-name:
  image: a-thing
  environment:
    TEST_ENV: FAKE
    MORE: ANOTHER
    KEY: VALUE
      YAML
    }

    before do
      allow(config).to receive(:image_tag).and_return('latest')
      allow(env).to receive(:evaluate_command).and_return app_name
      allow(env).to receive(:run_command)
      tutum_api = double("TutumApi", stack_by_name: {"#{app_name}-test": 'stack stuff'})
      allow(KumoTutum::TutumApi).to receive(:new).and_return tutum_api
      allow_any_instance_of(KumoTutum::StateValidator).to receive(:wait_for_state)
    end

    it "writes a stack file" do
      expect_any_instance_of(Tempfile).to receive(:write).with(configured_stack_file)
      subject
    end

    it 'runs the stack command'
    it 'deletes the tempfile?'
    it 'runs the tutum redeploy command'
    it "makes sure it waits until it's running"
  end
end
