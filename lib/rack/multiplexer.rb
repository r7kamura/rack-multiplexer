require "rack/multiplexer/version"
require "rack/request"

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
        routes[env["REQUEST_METHOD"]].find {|route| route.match?(path) } ||
        routes["ANY"].find {|route| route.match?(path) } ||
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

    # @routes are indexed by method.
    def routes
      @routes ||= Hash.new {|hash, key| hash[key] = [] }
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

    class Route
      PLACEHOLDER_REGEXP = /:(\w+)/

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
          segments << segment.gsub(PLACEHOLDER_REGEXP, "([^#?/]+)")
          if key = Regexp.last_match(1)
            keys << key
          end
        end
        return Regexp.new("\\A#{segments.join(?/)}\\z"), keys
      end
    end
  end
end
