module KumoDockerCloud
  class Error < RuntimeError; end
  class ServiceDeployError < RuntimeError; end
  class HaproxySocketError < RuntimeError; end
end
