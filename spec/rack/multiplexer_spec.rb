require "spec_helper"
require "active_support/core_ext/object/to_query"
require "active_support/core_ext/object/try"

describe Rack::Multiplexer do
  let(:application) do
    ->(env) {
      [
        200,
        {},
        ["#{env['PATH_INFO']}?#{env['rack.request.query_hash'].try(:to_param)}&#{env['QUERY_STRING']}"]
      ]
    }
  end

  let(:env) do
    {
      "SCRIPT_NAME" => "",
      "SERVER_NAME" => "localhost",
      "SERVER_PORT" => "80",
      "rack.input" => StringIO.new(""),
    }
  end

  describe "#call" do
    context "with unrelated path request" do
      it "sends request to default not found application" do
        multiplexer = described_class.new
        multiplexer.call(env.merge("REQUEST_METHOD" => "GET", "PATH_INFO" => "/a")).should == [
          404,
          { "Content-Type" => "text/plain", "Content-Length" => "0" },
          [""],
        ]
      end
    end

    context "with custom not found application" do
      it "sends request to custom not found application" do
        multiplexer = described_class.new(->(env) { [404, {}, ["custom"]] })
        multiplexer.call(env.merge("REQUEST_METHOD" => "GET", "PATH_INFO" => "/a")).should == [
          404,
          {},
          ["custom"],
        ]
      end
    end

    context "with unrelated method" do
      it "delegates to not found application" do
        multiplexer = described_class.new
        multiplexer.post("/a", application)
        multiplexer.call(env.merge("REQUEST_METHOD" => "GET", "PATH_INFO" => "/a"))[0].should == 404
      end
    end

    context "with related method" do
      it "delegates to registered application" do
        multiplexer = described_class.new
        multiplexer.get("/a", application)
        multiplexer.call(env.merge("REQUEST_METHOD" => "GET", "PATH_INFO" => "/a"))[0].should == 200
      end
    end

    context "with 2 registered routes" do
      it "delegates to first-registered application" do
        multiplexer = described_class.new
        multiplexer.get("/a", application)
        multiplexer.get("/:any", application)
        multiplexer.call(env.merge("REQUEST_METHOD" => "GET", "PATH_INFO" => "/a"))[2][0].should == "/a?&"
      end
    end

    context "with path parameters pattern" do
      it "delegates with rack.request.query_hash" do
        multiplexer = described_class.new
        multiplexer.get("/:any", application)
        multiplexer.get("/a", application)
        multiplexer.call(env.merge("REQUEST_METHOD" => "GET", "PATH_INFO" => "/a"))[2][0].should == "/a?any=a&"
      end
    end

    context "with duplicated params in path & query string" do
      it "delegates with rack.request.query_hash & QUERY_STRING" do
        multiplexer = described_class.new
        multiplexer.get("/:any", application)
        multiplexer.call(
          env.merge(
            "REQUEST_METHOD" => "GET",
            "PATH_INFO" => "/a",
            "QUERY_STRING" => "any=b"
          )
        )[2][0].should == "/a?any=a&any=b"
      end
    end

    context "with block routing" do
      it "delegates to given block as rack application" do
        multiplexer = described_class.new
        multiplexer.get("/a") {|env| [200, {}, ["a"]] }
        multiplexer.call(env.merge("REQUEST_METHOD" => "GET", "PATH_INFO" => "/a"))[0].should == 200
      end
    end

    context "with any routing" do
      it "matches any method" do
        multiplexer = described_class.new
        multiplexer.any("/a", application)
        multiplexer.call(env.merge("REQUEST_METHOD" => "GET", "PATH_INFO" => "/a"))[0].should == 200
        multiplexer.call(env.merge("REQUEST_METHOD" => "POST", "PATH_INFO" => "/a"))[0].should == 200
        multiplexer.call(env.merge("REQUEST_METHOD" => "HEAD", "PATH_INFO" => "/a"))[0].should == 200
      end
    end
  end
end
