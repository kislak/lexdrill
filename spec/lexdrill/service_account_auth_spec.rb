# frozen_string_literal: true

RSpec.describe Lexdrill::ServiceAccountAuth do
  around do |example|
    Dir.mktmpdir("lexdrill-service-account-auth-spec") do |dir|
      @path = File.join(dir, ".drill.gcp-service-account.json")
      example.run
    end
  end

  before { stub_const("Lexdrill::ServiceAccountAuth::PATH", @path) }

  # A throwaway key generated once for the whole suite — small on purpose
  # since it only needs to be cryptographically valid, not secure.
  let(:rsa_key) { @rsa_key ||= OpenSSL::PKey::RSA.generate(512) }

  def write_key_file(client_email: "connector@example.iam.gserviceaccount.com")
    File.write(@path, JSON.generate("client_email" => client_email, "private_key" => rsa_key.to_pem))
  end

  def token_response(code, body)
    Lexdrill::HTTPClient::Response.new(code, JSON.generate(body))
  end

  def decode_segment(segment)
    JSON.parse(Base64.urlsafe_decode64(segment))
  end

  describe ".configured?" do
    it "is false until a key file exists" do
      expect(described_class.configured?).to be false
    end

    it "is true once a key file exists" do
      write_key_file
      expect(described_class.configured?).to be true
    end
  end

  describe ".fetch_token!" do
    it "signs a genuinely valid JWT and exchanges it for an access token" do
      write_key_file(client_email: "connector@lexdrill-502012.iam.gserviceaccount.com")
      sent_assertion = nil
      allow(Lexdrill::HTTPClient).to receive(:post_form) do |_url, params|
        sent_assertion = params["assertion"]
        token_response(200, "access_token" => "at1", "expires_in" => 3600)
      end

      expect(described_class.fetch_token!).to eq("at1")

      header_segment, claims_segment, signature_segment = sent_assertion.split(".")
      expect(decode_segment(header_segment)).to eq("alg" => "RS256", "typ" => "JWT")
      claims = decode_segment(claims_segment)
      expect(claims["iss"]).to eq("connector@lexdrill-502012.iam.gserviceaccount.com")
      expect(claims["scope"]).to eq("https://www.googleapis.com/auth/spreadsheets")
      expect(claims["aud"]).to eq("https://oauth2.googleapis.com/token")
      expect(claims["exp"] - claims["iat"]).to eq(3600)

      signing_input = "#{header_segment}.#{claims_segment}"
      signature = Base64.urlsafe_decode64(signature_segment)
      expect(rsa_key.public_key.verify(OpenSSL::Digest.new("SHA256"), signature, signing_input)).to be true
    end

    it "sends the correct grant_type" do
      write_key_file
      allow(Lexdrill::HTTPClient).to receive(:post_form)
        .and_return(token_response(200, "access_token" => "at1", "expires_in" => 3600))

      described_class.fetch_token!

      expect(Lexdrill::HTTPClient).to have_received(:post_form)
        .with(described_class::TOKEN_URL, hash_including("grant_type" => described_class::GRANT_TYPE))
    end

    it "raises AuthError when no key file exists" do
      expect { described_class.fetch_token! }.to raise_error(described_class::AuthError, /no service account key/)
    end

    it "raises AuthError when the key file isn't valid JSON" do
      File.write(@path, "not json")
      expect { described_class.fetch_token! }.to raise_error(described_class::AuthError, /not valid JSON/)
    end

    it "raises AuthError when Google rejects the credentials" do
      write_key_file
      allow(Lexdrill::HTTPClient).to receive(:post_form).and_return(
        token_response(400, "error" => "invalid_grant", "error_description" => "Invalid JWT signature")
      )

      expect { described_class.fetch_token! }
        .to raise_error(described_class::AuthError, /Invalid JWT signature/)
    end
  end
end
