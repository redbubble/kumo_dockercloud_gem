module KumoDockerCloud
  class CredentialsDecrypter
    def decrypt(credentials)
      kms = KumoKi::KMS.new

      {
        username: kms.decrypt(credentials[:encrypted_dockercloud_user][5..-1]),
        api_key: kms.decrypt(credentials[:encrypted_dockercloud_apikey][5..-1])
      }
    rescue
      raise Error.new("Could not decrypt deployment credentials")
    end
  end
end
