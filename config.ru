require "rack-multiplexer"

multiplexer = Rack::Multiplexer.new
multiplexer.get("/a", ->(env) { [200, {}, ["a"]] })
multiplexer.get("/b", ->(env) { [200, {}, ["b"]] })
multiplexer.post("/c", ->(env) { [200, {}, ["c"]] })
multiplexer.put("/d", ->(env) { [200, {}, ["c"]] })
multiplexer.delete("/e", ->(env) { [200, {}, ["c"]] })
multiplexer.get("/f/:g", ->(env) { [200, {}, [env["rack.request.query_hash"]["g"]]] })

run multiplexer
