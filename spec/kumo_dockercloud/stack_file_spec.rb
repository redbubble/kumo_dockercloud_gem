describe KumoDockerCloud::StackFile do

  let(:app_name) { 'application-stack-name' }
  let(:config) { KumoDockerCloud::EnvironmentConfig.new(app_name: app_name, env_name: 'test', config_path: 'a path') }
  let(:env_vars) { {app_name => {'KEY' => 'VALUE'}} }
  let(:plain_text_secrets) do
    {
      'TEST_ENV' => 'FAKE',
      'MORE' => 'ANOTHER'
    }
  end

  before do
    allow(KumoDockerCloud::EnvironmentConfig).to receive(:new).and_return(config)
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
            'KEY' => 'VALUE'
          }
        })
      end

      context 'and environment variables that contain symbols that need special escaping' do
        let(:stack_template) do
          <<-eos
            application-stack-name:
              image: a-thing
              environment:
                TEST: 123$abc
          eos
        end

        # to work around https://github.com/docker/dockercloud-cli/issues/17
        it 'escapes environment variables that contain $ with an extra $' do

          expect(subject).to eq(app_name => {
            'image' => 'a-thing',
            'environment' => {
              'TEST' => '123$$abc',
              'KEY' => 'VALUE'
            }
          })
        end
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
            'KEY' => 'VALUE'
          }
        })
      end
    end

    context 'with other services' do
      let(:env_vars) do
        {
          app_name => {'KEY' => 'VALUE'},
          "another_service" => {'KEY2' => 'VALUE2'}
        }
      end

      let(:stack_template) do
        <<-eos
        application-stack-name:
          image: a-thing
        another_service:
          image: another
          environment:
            KEY: thing
            KEY2: OLD_VALUE
        third_service:
          image: third
        eos
      end

      let(:expected_stack_file) do
        {
          app_name => {
            'image' => 'a-thing',
            'environment' => {
              'KEY' => 'VALUE'
            }},
          'another_service' => {
            'image' => 'another',
            'environment' => {
              'KEY' => 'thing',
              'KEY2' => 'VALUE2',
            }
          },
          'third_service' => {
            'image' => 'third'
          }
        }
      end

      it 'should create the environment with variables for other services' do
        expect(subject).to eq(expected_stack_file)
      end

      context 'the key is a symbol' do
        let(:env_vars) do
          {
            app_name => {'KEY' => 'VALUE'},
            another_service: {'KEY2' => 'VALUE2'}
          }
        end

        it 'handles symbols the same way as strings' do
          expect(subject).to eq(expected_stack_file)
        end
      end
    end
  end
end
