class DockerCloud::HaproxyCommand
  def execute
    process_output
  end
end


DockerCloud::HaproxyCommand.new('container_id').execute('show stat') do |output|
  CSV.parse(output)
end

DockerCloud::HaproxyCommand.new('container_id').execute('disable server RBA') do |output|
  output
end

DockerCloud::HaproxyCommand.new('container_id').execute('disable server RBA') do |output|
  output
end
