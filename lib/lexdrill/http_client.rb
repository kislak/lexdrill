# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

# The only place lexdrill talks to Net::HTTP directly. Lexdrill::GoogleAuth
# (form-encoded OAuth endpoints) and Lexdrill::SheetsClient (JSON REST) both
# go through here, so every low-level connectivity failure (DNS, timeout,
# TLS, connection refused) is normalized to a single NetworkError for
# callers to handle, instead of each caller needing to know every possible
# Net::HTTP/OpenSSL/socket exception class.
module Lexdrill::HTTPClient
  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 15

  Response = Struct.new(:code, :body)

  class NetworkError < StandardError; end

  # Net::HTTP's 2-arg instance `#post(path, body)` sends no Content-Type
  # header at all — most token endpoints tolerate that (defaulting to
  # form-urlencoded), but not all do, so this sets it explicitly.
  def self.post_form(url, params)
    uri = URI(url)
    perform(uri) do |http|
      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/x-www-form-urlencoded"
      request.body = URI.encode_www_form(params)
      http.request(request)
    end
  end

  def self.json_post(url, body:, headers: {})
    json_request(Net::HTTP::Post, url, body, headers)
  end

  def self.json_put(url, body:, headers: {})
    json_request(Net::HTTP::Put, url, body, headers)
  end

  def self.json_get(url, headers: {})
    uri = URI(url)
    request = build_get_request(uri, headers)
    perform(uri) { |http| http.request(request) }
  end

  def self.build_get_request(uri, headers)
    request = Net::HTTP::Get.new(uri.request_uri)
    headers.each { |key, value| request[key] = value }
    request
  end
  private_class_method :build_get_request

  def self.json_request(method_class, url, body, headers)
    uri = URI(url)
    request = build_json_request(method_class, uri, body, headers)
    perform(uri) { |http| http.request(request) }
  end
  private_class_method :json_request

  def self.build_json_request(method_class, uri, body, headers)
    request = method_class.new(uri.request_uri)
    headers.each { |key, value| request[key] = value }
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(body)
    request
  end
  private_class_method :build_json_request

  def self.perform(uri, &block)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                                                   open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT, &block)
    Response.new(response.code.to_i, response.body)
  rescue StandardError => error
    raise NetworkError, error.message
  end
  private_class_method :perform
end
