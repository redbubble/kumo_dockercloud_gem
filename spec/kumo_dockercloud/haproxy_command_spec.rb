require 'spec_helper'

describe KumoDockerCloud::HaproxyCommand do
  describe '#execute' do
    let(:command) { 'enable' }
    let(:dc_client) { double(:dc_client, headers: nil)}
    let(:container_id) { 'id' }
    let(:api) { instance_double(DockerCloud::ContainerStreamAPI, on: nil, run!: nil)}
    let(:cmd) { %(sh -c "echo #{command} | nc -U /var/run/haproxy.stats") }
    let(:handler) { KumoDockerCloud::HaproxyEventHandler.new }


    subject { described_class.new(container_id, dc_client).execute(command) }

    it 'uses the ContainerStreamAPI with the passed in command' do
      expect(DockerCloud::ContainerStreamAPI).to receive(:new).with(container_id, cmd, dc_client.headers, dc_client).and_return(api)
      subject
    end

    before do
      allow(DockerCloud::ContainerStreamAPI).to receive(:new).with(container_id, cmd, dc_client.headers, dc_client).and_return(api)
    end

    it 'configures the callback handlers' do
      allow(KumoDockerCloud::HaproxyEventHandler).to receive(:new).and_return(handler)

      expect(api).to receive(:on).with(:open)
      expect(api).to receive(:on).with(:message)
      expect(api).to receive(:on).with(:error)
      expect(api).to receive(:on).with(:close)
      subject
    end

    it 'runs the event machine' do
      expect(api).to receive(:run!)
      subject
    end

    it 'returns the data from the callback handler' do
      allow(KumoDockerCloud::HaproxyEventHandler).to receive(:new).and_return(handler)
      expect(handler).to receive(:data)
      subject
    end
  end
end
