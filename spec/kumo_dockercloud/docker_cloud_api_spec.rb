require 'webmock/rspec'

describe KumoDockerCloud::DockerCloudApi do
  let(:username) { 'pebbles' }
  let(:api_key) { 'bam bam' }
  let(:api) { KumoDockerCloud::DockerCloudApi.new(username: username, api_key: api_key) }
  let(:stack) { double(DockerCloud::Stack, name: stack_name, services: services) }
  let(:stack_name) { "foo" }
  let(:services) { [] }

  describe '#initialize' do
    subject { api }

    it "passes through username and api_key from hash" do
      expect(::DockerCloud::Client).to receive(:new).with(username, api_key)
      subject
    end

    context "without params" do
      subject { KumoDockerCloud::DockerCloudApi.new }

      after do
        ENV.delete('DOCKERCLOUD_USER')
        ENV.delete('DOCKERCLOUD_APIKEY')
      end

      it "uses user name from env variable DOCKERCLOUD_USER" do
        ENV['DOCKERCLOUD_USER'] = username
        expect(::DockerCloud::Client).to receive(:new).with(username, anything)
        subject
      end

      it "uses api key from env variable DOCKERCLOUD_APIKEY" do
        ENV['DOCKERCLOUD_APIKEY'] = api_key
        expect(::DockerCloud::Client).to receive(:new).with(anything, api_key)
        subject
      end

    end
  end


  describe '#stack_by_name' do
    subject { api.stack_by_name(stack_name_in) }
    let(:stacks_mock) { double(DockerCloud::StackAPI, all: [stack] ) }

    before do
      allow_any_instance_of(::DockerCloud::Client).to receive(:stacks).and_return(stacks_mock)
    end

    context 'when you have 1 stack, with matching name' do
      let(:stack_name_in) { stack_name }

      it { should == stack }
    end

    context 'when you have 1 stack, with non-matching name' do
      let(:stack_name_in) { 'bar' }

      it { should be_nil }
    end

    context 'when your stacks have partially matching names' do
      let(:stack_name_in) { 'fo' }

      it { should be_nil }
    end

    context 'when you have no stacks' do
      let(:stack_name_in) { stack_name }
      let(:stacks_mock) { double(DockerCloud::StackAPI, all: [] ) }

      it { should be_nil }
    end
  end

  describe '#services_by_stack_name' do
    subject { api.services_by_stack_name(stack_name) }

    context 'when the stack exists' do
      before do
        allow(api).to receive(:stack_by_name).and_return(stack)
      end

      context 'without any services' do
        let(:services) { [] }
        it do
          expect(api).to receive(:stack_by_name).with(stack_name)
          subject
        end

        it 'returns a blank list' do
          expect(subject).to eq []
        end
      end

      context 'with services' do
        let(:service) { double(DockerCloud::Service) }
        let(:services) { [ service ] }
        let(:stack_name) { 'bar' }

        it 'returns list of service data' do
          expect(subject).to eq services
        end

        it 'appropriately passes through the correct stack name' do
          expect(api).to receive(:stack_by_name).with(stack_name)
          subject
        end
      end
    end

    context "when the stack doesn't exist" do
      before do
        allow(api).to receive(:stack_by_name).and_return(nil)
      end

      it 'returns a blank list' do
        expect(subject).to eq []
      end
    end
  end

  describe '#containers_by_stack_name' do
    subject { api.containers_by_stack_name(stack_name) }

    before do
      allow(api).to receive(:services_by_stack_name).and_return(services)
    end

    context 'with only 1 service' do
      let(:service) { double(DockerCloud::Service, containers: containers) }
      let(:services) { [service] }

      context 'without any containers' do
        let(:containers) { [] }

        it { should == [] }
      end

      context 'with multiple containers' do
        let(:container) { double(DockerCloud::Container) }
        let(:containers) { [container, container] }

        it { should == containers }
      end
    end

    context 'with multiple services' do
      let(:service1) { double(DockerCloud::Service, containers: containers1) }
      let(:service2) { double(DockerCloud::Service, containers: containers2) }
      let(:services) { [service1, service2] }

      let(:container) { double(DockerCloud::Container) }
      let(:containers1) { [container] }
      let(:containers2) { [container, container] }

      it { should == [container, container, container] }
    end
  end

  context 'forwarded methods' do
    describe '#services' do
      let(:client) { instance_double(DockerCloud::Client) }
      let(:api) { KumoDockerCloud::DockerCloudApi.new(username: username, api_key: api_key, client: client) }

      it 'forwards to the docker cloud client' do
        expect(client).to receive(:services)
        api.services
      end
    end
  end
end
