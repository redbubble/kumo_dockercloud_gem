module KumoDockerCloud
  class Error < RuntimeError; end
  class ServiceDeployError < RuntimeError; end
  class EnvironmentApplyError < RuntimeError; end
  class StackCheckError < RuntimeError; end
  class InvalidStackError < RuntimeError; end
end
