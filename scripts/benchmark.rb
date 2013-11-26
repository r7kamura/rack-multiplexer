# Benchmark script for comparison of the routing algorithm between v0.0.2 and v0.0.3.
# In my laptop environment, v0.0.3 is 17x faster than 0.0.2 with 676 routes & 100,000 tries.

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "rack/multiplexer"
require "benchmark"

multiplexer = Rack::Multiplexer.new
(?a..?z).each do |head|
  (?a..?z).each do |tail|
    multiplexer.get("/#{head}{tail}") do
      [200, {}, ["OK"]]
    end
  end
end

env = {
  "PATH_INFO" => "/mm",
  "REQUEST_METHOD" => "GET",
}

n = 100_000
puts Benchmark::CAPTION
puts Benchmark.measure {
  n.times do
    multiplexer.call(env)
  end
}
