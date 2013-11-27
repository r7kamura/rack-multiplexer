$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "rack/multiplexer"
require "benchmark"

characters = (?a..?z).to_a
env = {
  "PATH_INFO" => "/mm",
  "REQUEST_METHOD" => "GET",
}
n = 100_000

26.times do |i|
  multiplexer = Rack::Multiplexer.new
  characters[0, i + 1].each do |character|
    multiplexer.get("/#{character}") do
      [200, {}, ["OK"]]
    end
  end

  before = Time.now
  n.times do
    multiplexer.call(env)
  end
  puts Time.now - before
end
