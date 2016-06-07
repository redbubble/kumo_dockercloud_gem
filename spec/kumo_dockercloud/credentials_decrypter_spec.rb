require 'spec_helper'

describe KumoDockerCloud::CredentialsDecrypter do
  describe '#decrypt' do
    let(:encrypted_user) { 'encrypted_user' }
    let(:encrypted_apikey) { 'encrypted_apikey' }
    let(:plaintext_user) { 'plaintext_user' }
    let(:plaintext_apikey) { 'plaintext_apikey' }
    let(:encrypted) { { encrypted_dockercloud_user: "[ENC,#{encrypted_user}", encrypted_dockercloud_apikey: "[ENC,#{encrypted_apikey}" } }

    let(:kms) { instance_double(KumoKi::KMS) }

    subject { described_class.new.decrypt(encrypted) }

    before do
      allow(KumoKi::KMS).to receive(:new).and_return(kms)
      allow(kms).to receive(:decrypt).with(encrypted_user).and_return(plaintext_user)
      allow(kms).to receive(:decrypt).with(encrypted_apikey).and_return(plaintext_apikey)
    end

    it 'decrypts encrypted credentials' do
      expect(subject).to eq({ username: plaintext_user, api_key: plaintext_apikey })
    end

    it 'throws an exception if the credentials cannot be encrypted' do
      allow(kms).to receive(:decrypt).and_raise(KumoKi::DecryptionError)
      expect { subject }.to raise_error(KumoDockerCloud::Error, 'Could not decrypt deployment credentials')
    end
  end
end
