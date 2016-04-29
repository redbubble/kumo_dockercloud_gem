describe KumoDockerCloud::ServiceCheck do
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
end