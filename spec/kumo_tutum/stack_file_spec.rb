describe KumoTutum::StackFile do

  let(:app_name) { 'application-stack-name' }
  let(:config) { KumoTutum::EnvironmentConfig.new(app_name: app_name, env_name: 'test', config_path: 'a path') }
  let(:env_vars) { {'KEY' => 'VALUE'} }
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

  describe '.create_from_template' do
    subject { described_class.create_from_template(stack_template, config, env_vars) }

    let(:stack_template) do
      <<-eos
        application-stack-name:
          image: a-thing
      eos
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
end