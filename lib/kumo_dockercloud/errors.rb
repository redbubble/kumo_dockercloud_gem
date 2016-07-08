module KumoDockerCloud
  class Error < RuntimeError; end
  class ServiceDeployError < RuntimeError; end
  class HaproxySocketError < RuntimeError; end
  class HAProxyStateError < Error; end
  class EnvironmentApplyError < RuntimeError; end
  class StackCheckError < RuntimeError; end
  class InvalidStackError < RuntimeError; end
  class StackFileError < RuntimeError; end
end
