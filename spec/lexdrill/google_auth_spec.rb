# frozen_string_literal: true

RSpec.describe Lexdrill::GoogleAuth do
  around do |example|
    Dir.mktmpdir("lexdrill-google-auth-spec") do |dir|
      @path = File.join(dir, ".drill.gcp-token.json")
      example.run
    end
  end

  before do
    stub_const("Lexdrill::GoogleAuth::PATH", @path)
    allow(described_class).to receive(:sleep)
  end

  def http_response(body)
    Lexdrill::HTTPClient::Response.new(200, JSON.generate(body))
  end

  describe ".ensure_token!" do
    it "triggers login when no token file exists" do
      device = { "device_code" => "dc", "user_code" => "ABCD", "verification_url" => "https://x", "interval" => 0 }
      allow(Lexdrill::HTTPClient).to receive(:post_form)
        .with(described_class::DEVICE_CODE_URL, anything).and_return(http_response(device))
      allow(Lexdrill::HTTPClient).to receive(:post_form)
        .with(described_class::TOKEN_URL, anything)
        .and_return(http_response("access_token" => "at1", "refresh_token" => "rt1", "expires_in" => 3600))

      expect { described_class.ensure_token! }.to output(/enter this code: ABCD/).to_stdout
      expect(JSON.parse(File.read(@path))["access_token"]).to eq("at1")
    end

    it "returns the cached access token without any HTTP call when still valid" do
      File.write(@path, JSON.generate("access_token" => "cached", "refresh_token" => "rt",
                                      "expires_at" => Time.now.to_i + 500))

      expect(Lexdrill::HTTPClient).not_to receive(:post_form)
      expect(described_class.ensure_token!).to eq("cached")
    end

    it "refreshes when the cached token has expired" do
      File.write(@path, JSON.generate("access_token" => "old", "refresh_token" => "rt",
                                      "expires_at" => Time.now.to_i - 10))
      allow(Lexdrill::HTTPClient).to receive(:post_form)
        .with(described_class::TOKEN_URL, hash_including("grant_type" => "refresh_token"))
        .and_return(http_response("access_token" => "new", "expires_in" => 3600))

      expect(described_class.ensure_token!).to eq("new")
    end
  end

  describe ".login!" do
    let(:device) do
      { "device_code" => "dc", "user_code" => "ABCD", "verification_url" => "https://x", "interval" => 0 }
    end

    before do
      allow(Lexdrill::HTTPClient).to receive(:post_form)
        .with(described_class::DEVICE_CODE_URL, anything).and_return(http_response(device))
    end

    it "polls through authorization_pending and slow_down before succeeding" do
      responses = [
        http_response("error" => "authorization_pending"),
        http_response("error" => "slow_down"),
        http_response("access_token" => "at1", "refresh_token" => "rt1", "expires_in" => 3600)
      ]
      allow(Lexdrill::HTTPClient).to receive(:post_form)
        .with(described_class::TOKEN_URL, anything) { responses.shift }

      token = nil
      expect { token = described_class.login! }.to output.to_stdout
      expect(token).to eq("at1")
    end

    it "raises AuthError when the user denies access" do
      allow(Lexdrill::HTTPClient).to receive(:post_form)
        .with(described_class::TOKEN_URL, anything).and_return(http_response("error" => "access_denied"))

      expect { described_class.login! }.to output.to_stdout.and raise_error(described_class::AuthError, /access_denied/)
    end

    it "raises AuthError once the device code's own deadline has passed" do
      expired_device = device.merge("expires_in" => -1)
      allow(Lexdrill::HTTPClient).to receive(:post_form)
        .with(described_class::DEVICE_CODE_URL, anything).and_return(http_response(expired_device))

      expect { described_class.login! }.to output.to_stdout.and raise_error(described_class::AuthError, /expired/)
    end
  end

  describe ".refresh!" do
    it "persists the new access token and re-chmods the file to 0600" do
      File.write(@path, JSON.generate("access_token" => "old", "refresh_token" => "rt",
                                      "expires_at" => Time.now.to_i - 10))
      allow(Lexdrill::HTTPClient).to receive(:post_form)
        .with(described_class::TOKEN_URL, hash_including("grant_type" => "refresh_token"))
        .and_return(http_response("access_token" => "new", "expires_in" => 3600))

      described_class.refresh!

      expect(JSON.parse(File.read(@path))["access_token"]).to eq("new")
      expect(File.stat(@path).mode & 0o777).to eq(0o600)
    end

    it "deletes the token file and raises AuthError on invalid_grant" do
      File.write(@path, JSON.generate("access_token" => "old", "refresh_token" => "rt",
                                      "expires_at" => Time.now.to_i - 10))
      response = Lexdrill::HTTPClient::Response.new(400, JSON.generate("error" => "invalid_grant",
                                                                       "error_description" => "revoked"))
      allow(Lexdrill::HTTPClient).to receive(:post_form)
        .with(described_class::TOKEN_URL, anything).and_return(response)

      expect { described_class.refresh! }.to raise_error(described_class::AuthError, /revoked/)
      expect(File.exist?(@path)).to be false
    end
  end
end
