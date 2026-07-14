# frozen_string_literal: true

require "json"
require "fileutils"

# Handles the Google OAuth 2.0 Device Authorization Grant ("visit this URL,
# enter this code") so `drill export` can write to a Sheet as the user's own
# Google account, without ever needing a service account key.
#
# CLIENT_ID/CLIENT_SECRET below are NOT confidential for this OAuth client
# type ("TVs and Limited Input devices" / installed-app device flow) — see
# README's "Google Sheets export" section for why it's safe to ship these in
# published gem source. The actual secret is the refresh_token persisted at
# PATH below, obtained only after this specific user's own interactive
# consent, which never leaves this machine and is never published.
module Lexdrill::GoogleAuth
  PATH = Lexdrill::Config.path("gcp-token.json")

  CLIENT_ID = "608056429593-ncdgh4bnfpuf9486l2rlt7g763h1gl6g.apps.googleusercontent.com"
  CLIENT_SECRET = "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"

  SCOPE = "https://www.googleapis.com/auth/spreadsheets"
  DEVICE_CODE_URL = "https://oauth2.googleapis.com/device/code"
  TOKEN_URL = "https://oauth2.googleapis.com/token"
  GRANT_TYPE_DEVICE = "urn:ietf:params:oauth:grant-type:device_code"
  DEFAULT_POLL_INTERVAL = 5
  DEFAULT_EXPIRES_IN = 1800
  EXPIRY_SKEW = 60 # seconds of safety margin before treating a token as expired

  class AuthError < StandardError; end

  def self.ensure_token!
    return login! unless configured?

    data = load_token
    return data["access_token"] if Time.now.to_i < data["expires_at"].to_i

    refresh!
  end

  def self.configured?
    File.exist?(PATH)
  end

  def self.clear!
    FileUtils.rm_f(PATH)
  end

  def self.login!
    device = request_device_code
    print_instructions(device)
    poll_for_token(device)
  end

  def self.request_device_code
    response = Lexdrill::HTTPClient.post_form(DEVICE_CODE_URL, { "client_id" => CLIENT_ID, "scope" => SCOPE })
    JSON.parse(response.body)
  end
  private_class_method :request_device_code

  def self.print_instructions(device)
    puts "To let lexdrill export to Google Sheets, visit:"
    puts "  #{device['verification_url']}"
    puts "and enter this code: #{device['user_code']}"
    puts "Waiting for you to approve..."
  end
  private_class_method :print_instructions

  def self.poll_for_token(device)
    interval = (device["interval"] || DEFAULT_POLL_INTERVAL).to_i
    deadline = Time.now.to_i + (device["expires_in"] || DEFAULT_EXPIRES_IN).to_i
    loop do
      check_not_expired(deadline)
      sleep(interval)
      outcome = classify_poll_result(attempt_token_exchange(device["device_code"]))
      return outcome[:token] if outcome[:done]

      interval += 5 if outcome[:slow_down]
    end
  end
  private_class_method :poll_for_token

  def self.check_not_expired(deadline)
    return if Time.now.to_i <= deadline

    raise AuthError, "device code expired before authorization completed; run the command again"
  end
  private_class_method :check_not_expired

  def self.classify_poll_result(result)
    return { done: true, token: persist_token(result) } if result["access_token"]

    error = result["error"]
    return { done: false } if error == "authorization_pending"
    return { done: false, slow_down: true } if error == "slow_down"

    raise AuthError, "Google authorization failed: #{error}"
  end
  private_class_method :classify_poll_result

  def self.attempt_token_exchange(device_code)
    response = Lexdrill::HTTPClient.post_form(TOKEN_URL, {
                                                "client_id" => CLIENT_ID, "client_secret" => CLIENT_SECRET,
                                                "device_code" => device_code, "grant_type" => GRANT_TYPE_DEVICE
                                              })
    JSON.parse(response.body)
  end
  private_class_method :attempt_token_exchange

  def self.refresh!
    data = load_token
    params = {
      "client_id" => CLIENT_ID, "client_secret" => CLIENT_SECRET,
      "refresh_token" => data["refresh_token"], "grant_type" => "refresh_token"
    }
    handle_refresh_response(Lexdrill::HTTPClient.post_form(TOKEN_URL, params), data)
  end

  def self.handle_refresh_response(response, data)
    body = JSON.parse(response.body)
    raise_invalid_grant(body) if response.code == 400 && body["error"] == "invalid_grant"

    data["access_token"] = body["access_token"]
    data["expires_at"] = Time.now.to_i + body["expires_in"].to_i - EXPIRY_SKEW
    save(data)
    data["access_token"]
  end
  private_class_method :handle_refresh_response

  def self.raise_invalid_grant(body)
    clear!
    raise AuthError, "Google access was revoked or expired (#{body['error_description']}); " \
                     "run `drill export` again to re-authorize"
  end
  private_class_method :raise_invalid_grant

  def self.persist_token(data)
    token = {
      "access_token" => data["access_token"],
      "refresh_token" => data["refresh_token"],
      "expires_at" => Time.now.to_i + data["expires_in"].to_i - EXPIRY_SKEW
    }
    save(token)
    token["access_token"]
  end
  private_class_method :persist_token

  def self.load_token
    JSON.parse(File.read(PATH))
  end
  private_class_method :load_token

  def self.save(token)
    File.write(PATH, JSON.generate(token))
    File.chmod(0o600, PATH) # the ONE lexdrill config file holding a real secret
  end
  private_class_method :save
end
