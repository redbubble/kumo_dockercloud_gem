describe KumoDockerCloud::EnvironmentConfig do
  let(:env_name) { 'test' }
  let(:app_name) { "app-foo" }
  let(:config_path) { File.join(__dir__, '../fixtures/config') }
  subject(:instance) { described_class.new(app_name: app_name, env_name: env_name, config_path: config_path) }

  let(:docker_cloud_api) { instance_double('KumoDockerCloud::DockerCloudApi') }
  before { allow(KumoDockerCloud::DockerCloudApi).to receive(:new).and_return docker_cloud_api }

  describe '#get_binding' do
    let(:services_for_stack) { [] }

    # Ruby binding can only be tested by
    # evaluating strings against the binding
    subject { eval(string, instance.get_binding) }

    describe '@env_name' do
      let(:string) { '@env_name' }

      it 'is taken from the given parameter' do
        expect(subject).to eq env_name
      end
    end
  end

  describe '#plain_text_secrets' do
    subject { instance.plain_text_secrets }

    context 'with no encrypted secrets' do
      let(:secrets_data) do
        {
          'testkey'  => 'someval',
          'moretest' => 'otherval'
        }
      end

      it do
        expect(subject).to eq secrets_data
      end
    end

    context 'with some encrypted secrets' do
      let(:env_name) { 'test_encrypted' }
      let(:plain_value) { 'otherval' }

      let(:kms) { double('KumoKi::KMS') }

      let(:plain_data) do
        {
          'testkey' => 'someval',
          'enctest' => plain_value
        }
      end

      before do
        allow(KumoKi::KMS).to receive(:new).and_return(kms)
        allow(kms).to receive(:decrypt).with('ZW5jcnlwdGVkIGJpbmFyeSBkYXRh').and_return(plain_value)
      end

      it do
        expect(subject).to eq plain_data
      end
    end
  end

  describe "#tagged_app_image" do
    subject { instance.tagged_app_image(service_name) }

    let(:service_name) { "app-foo-service-a" }

    before { expect(docker_cloud_api).to receive(:service_by_stack_and_service_name).with(instance.stack_name, service_name).and_return(service) }

    context "no service present in stack" do
      let(:service) { nil }

      it "returns the master application image" do
        expect(subject).to eq("redbubble/#{app_name}:master")
      end
    end

    context "service present in stack" do
      let(:service) { instance_double(DockerCloud::Service, image_name: current_image_name) }
      let(:current_image_name) { "redbubble/#{app_name}:14" }

      it "returns the current service image" do
        expect(subject).to eq(current_image_name)
      end
    end

  end

  context 'with API mocked' do
    before { allow(docker_cloud_api).to receive(:services_by_stack_name).with("#{app_name}-#{env_name}").and_return(services_for_stack) }

    describe '#image_name' do
      subject { instance.image_name }

      context 'when there is a service for the given stack' do
        let(:image_name) { 'redbubble/application-stack-name:1234' }
        let(:services_for_stack) { [ double(DockerCloud::Service, image_name: image_name) ] }

        it 'uses the pre-exisiting image name' do
          expect(subject).to eq image_name
        end
      end

      context 'when there is no service for the given stack' do
        let(:services_for_stack) { [] }

        it { expect(subject).to eq "redbubble/#{app_name}:master" }
      end
    end

    describe '#image_tag' do
      let(:services_for_stack) { [ double(DockerCloud::Service, image_name: image_name)] }

      subject { instance.image_tag }

      context "when the image name is 'redbubble/assete-wala:latest'" do
        let(:image_name) { 'redbubble/application-stack-name:latest' }
        it { expect(subject).to eq 'latest' }
      end
      context "when the image name is 'some-registry/mything:9999'" do
        let(:image_name) { 'some-registry/mything:9999' }
        it { expect(subject).to eq '9999' }
      end
    end
  end
end
