# frozen_string_literal: true

RSpec.describe Lexdrill::HTTPClient do
  def stub_http(&block)
    allow(Net::HTTP).to receive(:start) { |*_args, **_kwargs, &inner| inner.call(block.call) }
  end

  describe ".post_form" do
    it "posts form-encoded params and returns a Response with integer code and body" do
      http = instance_double(Net::HTTP, post: instance_double(Net::HTTPResponse, code: "200", body: '{"ok":true}'))
      stub_http { http }

      response = described_class.post_form("https://example.com/token", { "a" => "1" })

      expect(http).to have_received(:post).with("/token", "a=1")
      expect(response.code).to eq(200)
      expect(response.body).to eq('{"ok":true}')
    end
  end

  describe ".json_post" do
    it "sends a JSON body with the given headers and a Content-Type header" do
      request = instance_double(Net::HTTP::Post)
      allow(Net::HTTP::Post).to receive(:new).and_return(request)
      allow(request).to receive(:[]=)
      allow(request).to receive(:body=)

      http = instance_double(Net::HTTP, request: instance_double(Net::HTTPResponse, code: "200", body: "{}"))
      stub_http { http }

      response = described_class.json_post("https://example.com/x", body: { "a" => 1 }, headers: { "X" => "y" })

      expect(request).to have_received(:[]=).with("X", "y")
      expect(request).to have_received(:[]=).with("Content-Type", "application/json")
      expect(request).to have_received(:body=).with(JSON.generate({ "a" => 1 }))
      expect(response.code).to eq(200)
    end
  end

  describe ".json_put" do
    it "issues a PUT request" do
      request = instance_double(Net::HTTP::Put)
      allow(Net::HTTP::Put).to receive(:new).and_return(request)
      allow(request).to receive(:[]=)
      allow(request).to receive(:body=)

      http = instance_double(Net::HTTP, request: instance_double(Net::HTTPResponse, code: "200", body: "{}"))
      stub_http { http }

      response = described_class.json_put("https://example.com/x", body: {})

      expect(http).to have_received(:request).with(request)
      expect(response.code).to eq(200)
    end
  end

  describe ".json_get" do
    it "issues a GET request with the given headers and no body/content-type" do
      request = instance_double(Net::HTTP::Get)
      allow(Net::HTTP::Get).to receive(:new).and_return(request)
      allow(request).to receive(:[]=)

      http = instance_double(Net::HTTP, request: instance_double(Net::HTTPResponse, code: "200", body: "{}"))
      stub_http { http }

      response = described_class.json_get("https://example.com/x", headers: { "X" => "y" })

      expect(request).to have_received(:[]=).with("X", "y")
      expect(http).to have_received(:request).with(request)
      expect(response.code).to eq(200)
    end
  end

  describe "error normalization" do
    it "wraps any low-level failure in NetworkError" do
      allow(Net::HTTP).to receive(:start).and_raise(SocketError, "getaddrinfo failed")

      expect { described_class.post_form("https://example.com", {}) }
        .to raise_error(Lexdrill::HTTPClient::NetworkError, /getaddrinfo failed/)
    end
  end
end
