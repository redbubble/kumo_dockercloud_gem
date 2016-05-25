require 'spec_helper'

describe KumoDockerCloud::HaproxyCommand do
  describe '#execute' do
    let(:command) { 'enable' }
    let(:dc_client) { double(:dc_client, headers: nil)}
    let(:container_id) { 'id' }
    let(:api) { double(DockerCloud::ContainerStreamAPI, on: nil, run!: nil)}
    let(:cmd) { %(sh -c "echo #{command} | nc -U /var/run/haproxy.stats") }

    subject { described_class.new(container_id, dc_client).execute(command) }

    it 'uses the ContainerStreamAPI with the passed in command' do
      expect(DockerCloud::ContainerStreamAPI).to receive(:new).with(container_id, cmd, dc_client.headers, dc_client).and_return(api)
      subject
    end

    before do
      allow(DockerCloud::ContainerStreamAPI).to receive(:new).with(container_id, cmd, dc_client.headers, dc_client).and_return(api)
    end

    [:open, :message, :error, :close].each do |event|
      it "configures an on(#{event}) handler" do
        expect(api).to receive(:on).with(event)
        subject
      end
    end

    it 'runs the event machine' do
      expect(api).to receive(:run!)
      subject
    end
  end
end
