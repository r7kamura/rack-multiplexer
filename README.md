# Rack::Multiplexer
Provides a simple router & dispatcher for Rack applications as a Rack application.  
The routing algorithm has only O(1) time complexity in Ruby level because all routes are compiled into one Regexp.

## Installation
```
gem install rack-multiplexer
```

## Usage
For `rackup`.

```ruby
# config.ru
require "rack-multiplexer"

multiplexer = Rack::Multiplexer.new
multiplexer.get("/a", ->(env) { [200, {}, ["a"]] })
multiplexer.get("/b", ->(env) { [200, {}, ["b"]] })
multiplexer.put("/c", ->(env) { [200, {}, ["c"]] })
multiplexer.get("/d/:e", ->(env) { [200, {}, [env["rack.request.query_hash"]["e"]]] })

run multiplexer
```

## DSL
The block is with you, always.

```ruby
# config.ru
require "rack-multiplexer"

run Rack::Multiplexer.new {
  get "/a" do
    [200, {}, ["a"]]
  end

  get "/b/:c" do
    [200, {}, ["d"]]
  end
}
```
