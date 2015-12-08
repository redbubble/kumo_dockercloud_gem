require 'kumo_tutum/environment'
require 'kumo_tutum/environment_config'


describe KumoTutum::Environment do
  subject(:env) { described_class.new({name: 'rspec', env_vars: {'KEY' => 'VALUE'}, config_path: 'a path'}) }

  describe '#get_stack_file_data' do
    subject { env.get_stack_file_data(stack_template) }

    let(:config) { KumoTutum::EnvironmentConfig.new({env_name: 'rspec', config_path: 'a path'}) }
    let(:plain_text_secrets) { {
      'TEST_ENV' => 'FAKE',
      'MORE'     => 'ANOTHER',
    } }
    let(:stack_template) {
      <<-eos
          asset-wala:
            image: a-thing
      eos
    }

    before do
      allow(KumoTutum::EnvironmentConfig).to receive(:new).and_return(config)
      allow(config).to receive(:plain_text_secrets).and_return(plain_text_secrets)
    end

    it 'creates an EnvironmentConfig' do
      expect(KumoTutum::EnvironmentConfig).to receive(:new).with(hash_including(config_path: 'a path'))
      subject
    end

    it "adds environment variables to stack config" do
      expect(subject).to eq({
                              'asset-wala' => {
                                'image'       => 'a-thing',
                                'environment' => {
                                  "TEST_ENV" => "FAKE",
                                  "MORE"     => "ANOTHER",
                                  'KEY'      => 'VALUE',
                                }
                              }
                            })
    end

    context "with some existing environment" do
      let(:stack_template) {
        <<-eos
          asset-wala:
            image: a-thing
            environment:
              TEST: thing
        eos
      }
      it "should add new secrets to the environment" do
        expect(subject).to eq({
                                'asset-wala' => {
                                  'image'       => 'a-thing',
                                  'environment' => {
                                    'TEST'     => 'thing',
                                    'TEST_ENV' => 'FAKE',
                                    'MORE'     => 'ANOTHER',
                                    'KEY'      => 'VALUE',
                                  }
                                }
                              })
      end
    end

    context "without any existing environment" do
      let(:stack_template) {
        <<-eos
          asset-wala:
            image: a-thing
        eos
      }
      it "should create the environment with secrets in it" do
        expect(subject).to eq({
                                'asset-wala' => {
                                  'image'       => 'a-thing',
                                  'environment' => {
                                    'TEST_ENV' => 'FAKE',
                                    'MORE'     => 'ANOTHER',
                                    'KEY'      => 'VALUE',
                                  }
                                }
                              })
      end
    end
  end
end
