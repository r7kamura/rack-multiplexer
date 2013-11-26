require "rack/multiplexer/version"
require "rack/request"

# Provides a simple router & dispatcher for Rack applications as a Rack application.
# The routing algorithm has only O(1) time complexity because all routes are compiled into one Regexp.
#
# Example:
#
#   # config.ru
#   multiplexer = Rack::Multiplexer.new
#   multiplexer.get("/a", ->(env) { [200, {}, ["a"]] })
#   multiplexer.get("/b", ->(env) { [200, {}, ["b"]] })
#   multiplexer.put("/c", ->(env) { [200, {}, ["c"]] })
#   multiplexer.get("/d/:e", ->(env) { [200, {}, [env["rack.request.query_hash"]["e"]]] })
#   run multiplexer
#
module Rack
  class Multiplexer
    DEFAULT_NOT_FOUND_APPLICATION = ->(env) {
      [
        404,
        {
          "Content-Type" => "text/plain",
          "Content-Length" => "0",
        },
        [""],
      ]
    }

    def initialize(not_found_application = DEFAULT_NOT_FOUND_APPLICATION, &block)
      @not_found_application = not_found_application
      instance_eval(&block) if block
    end

    def call(env)
      path = env["PATH_INFO"]
      (
        routes[env["REQUEST_METHOD"]].find(path) ||
        routes["ANY"].find(path) ||
        @not_found_application
      ).call(env)
    end

    def get(pattern, application = nil, &block)
      append("GET", pattern, application || block)
    end

    def post(pattern, application = nil, &block)
      append("POST", pattern, application || block)
    end

    def put(pattern, application = nil, &block)
      append("PUT", pattern, application || block)
    end

    def delete(pattern, application = nil, &block)
      append("DELETE", pattern, application || block)
    end

    def any(pattern, application, &block)
      append("ANY", pattern, application || block)
    end

    def append(method, pattern, application)
      routes[method] << Route.new(pattern, application)
    end

    def routes
      @routes ||= Hash.new {|hash, key| hash[key] = Routes.new }
    end

    def default_not_found_application
      ->(env) {
        [
          404,
          {
            "Content-Type" => "text/plain",
            "Content-Length" => 0,
          },
          [""],
        ]
      }
    end

    class Routes
      def initialize
        @routes = []
      end

      def find(path)
        if regexp === path
          @routes.size.times do |i|
            return @routes[i] if Regexp.last_match("_#{i}")
          end
        end
      end

      def <<(route)
        @routes << route
      end

      private

      def regexp
        @regexp ||= begin
          regexps = @routes.map.with_index {|route, index| /(?<_#{index}>#{route.regexp})/ }
          /\A#{Regexp.union(regexps)}\z/
        end
      end
    end

    class Route
      PLACEHOLDER_REGEXP = /:(\w+)/

      attr_reader :regexp

      def initialize(pattern, application)
        @application = application
        @regexp, @keys = compile(pattern)
      end

      def call(env)
        request = Rack::Request.new(env)
        data = @regexp.match(env["PATH_INFO"])
        (data.size - 1).times {|i| request.update_param(@keys[i], data[i + 1]) }
        @application.call(request.env)
      end

      def match?(path)
        @regexp === path
      end

      def compile(pattern)
        keys = []
        segments = []
        pattern.split("/").each do |segment|
          segments << Regexp.escape(segment).gsub(PLACEHOLDER_REGEXP, "([^#?/]+)")
          if key = Regexp.last_match(1)
            keys << key
          end
        end
        return Regexp.new(segments.join(?/)), keys
      end
    end
  end
end
