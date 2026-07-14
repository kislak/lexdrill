# frozen_string_literal: true

require "json"
require "openssl"
require "base64"

# Authenticates to the Sheets API as a Google service account, using the
# JWT Bearer Token flow (RFC 7523) — no interactive consent, no refresh
# token to cache: a fresh short-lived JWT is signed and exchanged for an
# access token on every call. The service account's private key lives in a
# JSON file the user downloads themselves from Google Cloud Console and
# saves locally at PATH below — it is never embedded in gem source, never
# published, and lexdrill never writes or transmits it anywhere except in
# the signed JWT sent directly to Google's own token endpoint.
module Lexdrill::ServiceAccountAuth
  PATH = Lexdrill::Config.path("gcp-service-account.json")
  TOKEN_URL = "https://oauth2.googleapis.com/token"
  SCOPE = "https://www.googleapis.com/auth/spreadsheets"
  GRANT_TYPE = "urn:ietf:params:oauth:grant-type:jwt-bearer"
  TOKEN_LIFETIME = 3600

  class AuthError < StandardError; end

  def self.configured?
    File.exist?(PATH)
  end

  def self.fetch_token!
    key = load_key
    jwt = build_jwt(key)
    exchange_jwt(jwt)
  end

  def self.load_key
    JSON.parse(File.read(PATH))
  rescue Errno::ENOENT
    raise AuthError, "no service account key found at #{PATH} — see README's service account setup"
  rescue JSON::ParserError
    raise AuthError, "#{PATH} is not valid JSON"
  end
  private_class_method :load_key

  def self.build_jwt(key)
    claims = jwt_claims(key.fetch("client_email"))
    signing_input = "#{encode_segment(jwt_header)}.#{encode_segment(claims)}"
    signature = sign(signing_input, key.fetch("private_key"))
    "#{signing_input}.#{Base64.urlsafe_encode64(signature, padding: false)}"
  end
  private_class_method :build_jwt

  def self.jwt_header
    { "alg" => "RS256", "typ" => "JWT" }
  end
  private_class_method :jwt_header

  def self.jwt_claims(client_email)
    now = Time.now.to_i
    { "iss" => client_email, "scope" => SCOPE, "aud" => TOKEN_URL, "iat" => now, "exp" => now + TOKEN_LIFETIME }
  end
  private_class_method :jwt_claims

  def self.encode_segment(hash)
    Base64.urlsafe_encode64(JSON.generate(hash), padding: false)
  end
  private_class_method :encode_segment

  def self.sign(signing_input, private_key_pem)
    OpenSSL::PKey::RSA.new(private_key_pem).sign(OpenSSL::Digest.new("SHA256"), signing_input)
  end
  private_class_method :sign

  def self.exchange_jwt(jwt)
    response = Lexdrill::HTTPClient.post_form(TOKEN_URL, { "grant_type" => GRANT_TYPE, "assertion" => jwt })
    handle_token_response(response)
  end
  private_class_method :exchange_jwt

  def self.handle_token_response(response)
    body = JSON.parse(response.body)
    return body.fetch("access_token") if response.code == 200

    raise AuthError, "Google rejected the service account credentials: #{body['error_description'] || body['error']}"
  end
  private_class_method :handle_token_response
end
