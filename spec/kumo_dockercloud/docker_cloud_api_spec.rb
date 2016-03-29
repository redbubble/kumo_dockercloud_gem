require 'kumo_dockercloud/docker_cloud_api'
require 'webmock/rspec'

describe KumoDockerCloud::DockerCloudApi do
  describe '#initialize' do
    subject { described_class.new(options) }
    let(:docker_cloud_user_env) { 'nada user' }
    let(:docker_cloud_apikey_env) { 'nada key' }
    let(:dot_dockercloud_data) do
      <<-eos
        [auth]
        user = wilma
        apikey = letmein
      eos
    end
    let(:dot_dockercloud_io_object) { StringIO.new(dot_dockercloud_data) }

    before do
      allow(ENV).to receive(:[]).with('DOCKERCLOUD_USER').and_return(docker_cloud_user_env)
      allow(ENV).to receive(:[]).with('DOCKERCLOUD_APIKEY').and_return(docker_cloud_apikey_env)
      allow_any_instance_of(described_class).to receive(:docker_cloud_config_file).and_return(dot_dockercloud_io_object)
    end

    context 'appropriately fills default credentials' do
      context 'pass in username/api_key options' do
        let(:options) { { username: 'fred', api_key: 'barney' } }

        it 'uses options passed in' do
          expect(subject.headers['Authorization']).to eq('Basic ZnJlZDpiYXJuZXk=')
        end
      end

      context 'with env variables set' do
        let(:options) { {} }
        it 'sets username/password from env vars' do
          expect(subject.headers['Authorization']).to eq('Basic bmFkYSB1c2VyOm5hZGEga2V5')
        end
      end

      context 'reading ~/.docker-cloud' do
        let(:options) { {} }
        let(:docker_cloud_user_env) { nil }
        let(:docker_cloud_apikey_env) { nil }

        context 'new .docker-cloud file format' do

          let(:dot_dockercloud_data) do
            <<-eos
                [auth]
                user = barney
                apikey = betty
              eos
          end

          it do
            expect(subject.headers['Authorization']).to eq('Basic YmFybmV5OmJldHR5')
          end

          context "with env vars" do

            let(:docker_cloud_user_env) { "user" }
            let(:docker_cloud_apikey_env) { "key" }

            it do
              expect(subject.username).to eq "user"
            end


          end
        end

        it do
          expect(subject.username).to eq('wilma')
        end
      end
    end
  end

  context 'with API creds mocked' do
    subject(:api) { KumoDockerCloud::DockerCloudApi.new(username: 'pebbles', api_key: 'bam bam') }

    before do
      allow_any_instance_of(KumoDockerCloud::DockerCloudApi).to receive(:docker_cloud_config).and_return({})
    end

    describe '#docker_cloud_config_file' do
      context do
        subject { api.send(:docker_cloud_config_file) }

        it do
          expect(File).to receive(:expand_path).with('~/.docker-cloud').and_return(:dot_dockercloud_path)
          expect(File).to receive(:open).with(:dot_dockercloud_path).and_return(:output_data)

          expect(subject).to eq(:output_data)
        end
      end
    end

    describe '#stack_by_name' do
      subject { api.stack_by_name(stack_name) }
      let(:stacks_mock) { double('Tutum::TutumStacks', list: stack_hash_data) }

      before do
        allow(api).to receive(:stacks).and_return(stacks_mock)
      end

      context 'when you have 1 stack, with matching name' do
        let(:stack_name) { 'my thing' }
        let(:stack_hash_data) do
          {
            'objects' => [
              { 'name' => 'my thing' }
            ]
          }
        end
        it 'returns the correct stack' do
          expect(subject['name']).to eq('my thing')
        end
      end
      context 'when you have 1 stack, with non-matching name' do
        let(:stack_name) { 'my thing' }
        let(:stack_hash_data) do
          {
            'objects' => [
              { 'name' => 'my bad thing' }
            ]
          }
        end
        it do
          expect(subject).to be_nil
        end
      end
      context 'when your stacks have /matching/ but non-equal names' do
        let(:stack_name) { 'some name' }
        let(:stack_hash_data) do
          {
            'objects' => [
              { 'name' => 'not some name' },
              { 'name' => 'some name' },
              { 'name' => 'some name bad' }
            ]
          }
        end
        it 'returns the correct stack' do
          expect(subject['name']).to eq('some name')
        end
      end
      context 'when you have no stacks' do
        let(:stack_name) { 'some name' }
        let(:stack_hash_data) do
          {
            'objects' => []
          }
        end
        it do
          expect(subject).to be_nil
        end
      end
    end

    describe '#services_by_stack_name' do
      subject { api.services_by_stack_name(stack_name) }

      let(:stack_name) { 'my stack' }

      context 'when the stack exists' do
        before do
          allow(api).to receive(:stack_by_name).and_return('services' => services_list)
        end

        context 'without any services' do
          let(:services_list) { [] }
          it do
            expect(api).to receive(:stack_by_name).with('my stack')
            subject
          end

          it 'returns a blank list' do
            expect(subject).to eq []
          end
        end

        context 'with services' do
          let(:services_list) do
            [
              '/api/v1/services/my-thing',
              '/api/v1/services/the-other'
            ]
          end
          let(:services_mock) { double('Tutum::TutumServices') }
          let(:stack_name) { 'other stack' }

          before do
            allow(api).to receive(:services).and_return(services_mock)
            allow(services_mock).to receive(:get).with('my-thing').and_return(:my_thing_test)
            allow(services_mock).to receive(:get).with('the-other').and_return(:the_other_test)
          end

          it do
            expect(services_mock).to receive(:get).with('my-thing')
            subject
          end
          it do
            expect(services_mock).to receive(:get).with('the-other')
            subject
          end
          it 'returns list of service data' do
            expect(subject).to eq [:my_thing_test, :the_other_test]
          end
          it 'appropriately passes through the correct stack name' do
            expect(api).to receive(:stack_by_name).with('other stack')
            subject
          end
        end
      end

      context "when the stack doesn't exist" do
        let(:stack_list_json) do
          JSON.dump('objects' => [
            { 'name' => 'other' },
            { 'name' => 'bad' }
          ])
        end

        before do
          stub_request(:get, "https://pebbles:bam%20bam@cloud.docker.com/api/app/v1/stack/")
            .to_return(status: 200, body: stack_list_json)
        end

        it 'returns a blank list' do
          expect(subject).to eq []
        end
      end
    end

    describe '#containers_by_stack_name' do
      subject { api.containers_by_stack_name(stack_name) }

      let(:stack_name) { 'my stack' }
      let(:containers_mock) { double('Tutum::TutumContainers') }

      before do
        allow(api).to receive(:services_by_stack_name).and_return(services_list)
      end

      context 'with only 1 service' do
        let(:services_list) { [{ 'containers' => containers_list }] }

        context 'without any containers' do
          let(:containers_list) { [] }
          it do
            expect(api).to receive(:services_by_stack_name).with('my stack')
            subject
          end

          it 'returns a blank list' do
            expect(subject).to eq []
          end
        end

        context 'with containers' do
          let(:containers_list) do
            [
              '/api/v1/containers/my-thing',
              '/api/v1/containers/the-other'
            ]
          end

          before do
            allow(api).to receive(:containers).and_return(containers_mock)
            allow(containers_mock).to receive(:get).with('my-thing').and_return(:my_thing_test)
            allow(containers_mock).to receive(:get).with('the-other').and_return(:the_other_test)
          end

          it do
            expect(containers_mock).to receive(:get).with('my-thing')
            subject
          end
          it do
            expect(containers_mock).to receive(:get).with('the-other')
            subject
          end
          it 'returns list of container data' do
            expect(subject).to eq [:my_thing_test, :the_other_test]
          end
        end
      end
      context 'with multiple services' do
        let(:services_list) do
          [
            { 'containers' => ['/api/v1/containers/a', '/api/v1/containers/c'] },
            { 'containers' => ['/api/v1/containers/d', '/api/v1/containers/b'] }
          ]
        end
        let(:stack_name) { 'other stack' }

        before do
          allow(api).to receive(:containers).and_return(containers_mock)
          allow(containers_mock).to receive(:get).with('a').and_return(:test_a)
          allow(containers_mock).to receive(:get).with('b').and_return(:test_b)
          allow(containers_mock).to receive(:get).with('c').and_return(:test_c)
          allow(containers_mock).to receive(:get).with('d').and_return(:test_d)
        end

        it 'returns flat list of containers, in correct order' do
          expect(subject).to eq [:test_a, :test_c, :test_d, :test_b]
        end

        it 'appropriately passes through the correct stack name' do
          expect(api).to receive(:services_by_stack_name).with('other stack')
          subject
        end
      end
    end

    describe '#nodes_by_stack_name' do
      subject { api.nodes_by_stack_name(stack_name) }

      let(:stack_name) { 'other stack' }
      let(:nodes_mock) { double('Tutum::TutumNodes') }
      let(:containers_list) do
        [
          { 'node' => '/api/v1/nodes/my-thing' },
          { 'node' => '/api/v1/nodes/the-other' }
        ]
      end

      before do
        allow(api).to receive(:containers_by_stack_name).and_return(containers_list)
      end

      before do
        allow(api).to receive(:nodes).and_return(nodes_mock)
        allow(nodes_mock).to receive(:get).with('my-thing').and_return(:my_thing_test)
        allow(nodes_mock).to receive(:get).with('the-other').and_return(:the_other_test)
      end

      it do
        expect(nodes_mock).to receive(:get).with('my-thing')
        subject
      end
      it do
        expect(nodes_mock).to receive(:get).with('the-other')
        subject
      end
      it 'returns list of nodes data' do
        expect(subject).to eq [:my_thing_test, :the_other_test]
      end
      it 'appropriately passes through the correct stack name' do
        expect(api).to receive(:containers_by_stack_name).with('other stack')
        subject
      end
    end
  end
end

describe KumoDockerCloud do
  describe '#uuid_from_uri' do
    subject { described_class.uuid_from_uri(uri) }

    context "when passed '/api/v1/stack/87d8f2d6-14b8-4697-a0d6-f04984ca9628/'" do
      let(:uri) { '/api/v1/stack/87d8f2d6-14b8-4697-a0d6-f04984ca9628/' }
      it { expect(subject).to eq '87d8f2d6-14b8-4697-a0d6-f04984ca9628' }
    end
    context "when passed '/api/v1/fakething/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/'" do
      let(:uri) { '/api/v1/fakething/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/' }
      it { expect(subject).to eq 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' }
    end
  end
end
