require 'active_support'
require 'active_support/subscriber'
require 'rack'
require 'webrick'
require 'byebug'
require 'awesome_print'
AwesomePrint.irb!

require_relative 'hello_world/service_twirp.rb'

ActiveSupport::Notifications.subscribe('instrumenter.twirp') do |evt|
  data = {
    duration: evt.duration,
    allocations: evt.allocations,
    cpu_time: evt.cpu_time,
    idle_time: evt.idle_time,
    transaction_id: evt.transaction_id,
    payload: evt.payload
  }
  ap(data, indent: -2)
end

# Service implementation
class HelloWorldHandler
  def hello(req, env)
    sleep rand(3)
    raise "Exception raised in 'hello' handler" if rand() > 0.5
    { message: "Hello #{req.name}" }
  end
end

# Instantiate Service
instrumenter = ActiveSupport::Notifications.instrumenter
handler = HelloWorldHandler.new()
service = Example::HelloWorld::HelloWorldService.new(handler)

service.before do |rack_env, env|
  payload = {
    rack_env: rack_env,
    env: env
  }
  instrumenter.start "instrumenter.twirp", payload
end

service.on_success do |env|
  instrumenter.finish "instrumenter.twirp", nil
end

service.on_error do |_twerr, _env|
  instrumenter.finish "instrumenter.twirp", nil
end

service.exception_raised do |e, env|
  env[:exception] = {
    class: e.class,
    message: e.message,
    backtrace: e.backtrace.join("\n")
  }
end

# Mount on webserver
path_prefix = "/twirp/" + service.full_name
server = WEBrick::HTTPServer.new(
  Port: 8080,
  Logger: WEBrick::Log.new("/dev/null"),
  AccessLog: [],
)
server.mount path_prefix, Rack::Handler::WEBrick, service
server.start
