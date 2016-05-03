describe KumoDockerCloud::ServiceChecker do
  describe ".initialize" do
    context "defaults" do
      subject { described_class.new }

      it "has no checks" do
        expect(subject.checks).to be_empty
      end

      it "has a timeout of 300 seconds" do
        expect(subject.timeout).to eq(300)
      end
    end
  end

  describe '#verify' do
    let(:happy_check) { lambda { |container| expect(container).to eq(container); true } }
    let(:sad_check) { lambda { |container| expect(container).to eq(container); false } }
    let(:container) { double(:my_container) }
    let(:checks) {[happy_check]}
    let(:timeout) { 10 }

    let(:containers) { [container, container] }

    let(:service) { instance_double(KumoDockerCloud::Service, containers: containers) }

    subject { described_class.new(checks, timeout).verify(service) }

    context "all checks successful" do
      it "runs without incident" do
        subject
      end

      context "no checks" do
        let(:checks) { [] }

        it "runs without retrieving containers" do
          expect(service).not_to receive(:containers)
          subject
        end
      end
    end

    context "timing out check" do
      let(:timeout) { 1 }
      let(:checks) { [sad_check] }

      it "raises an error" do
        expect { subject }.to raise_error(KumoDockerCloud::ServiceDeployError, "One or more checks failed to pass within the timeout")
      end
    end
  end
end
