require 'rack'
require 'webrick'

services = [
    {name: "service"}
    # {name: "service_with_ruby_package"}
]

services.each do |service|
    # Generate tests for services
    success = system("cd #{service[:name]} && protoc --proto_path=. ./#{service[:name]}.proto --ruby_out=. --twirp_ruby_out=.")
    unless success
        puts "Failed to generate files for service #{service[:name]} during tests"
        Process.exit(1)
    end

    # Run tests on generated code
    require_relative "./#{service[:name]}/#{service[:name]}_pb.rb"
    require_relative "./#{service[:name]}/#{service[:name]}_twirp.rb"

    klass = Class.new
    klass.define_method(:hello) do |req, env|
        if req.name.empty?
            return Twirp::Error.invalid_argument("name is mandatory")
        end
        {message: "Hello #{req.name}"} 
    end

    # Start server in thread
    thr = Thread.new do
        service = Example::HelloWorld::HelloWorldService.new(klass.new)
        path_prefix = "/twirp/" + service.full_name
        server = WEBrick::HTTPServer.new(Port: 3000)
        server.mount path_prefix, Rack::Handler::WEBrick, service
        server.start
    end

    # Drive tests through client
    client = Example::HelloWorld::HelloWorldClient.new("http://localhost:3000/twirp")
    resp = client.hello(name: "world")
    puts resp.inspect
    if resp.error
        puts "Error calling hello: #{resp.error}"
        Process.exit(1)
    end
    if resp.data.message != "Hello world!"
        puts "Expected resp.message to be 'Hello world!', but got #{resp.data.message} instead"
        Process.exit(1)
    end
end

