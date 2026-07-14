# frozen_string_literal: true

# Resolves which configured Google Sheet target (drill remote / drill
# oauth) is currently active — whichever was set more recently — so
# `drill export`/`drill import`, `drill sheet`, and `drill inspect` all
# agree on a single answer.
module Lexdrill::RemoteTarget
  def self.kind
    remote_set = Lexdrill::Remote.configured?
    oauth_set = Lexdrill::OauthRemote.configured?
    return :remote if remote_set && (!oauth_set || newer?(Lexdrill::Remote::PATH, Lexdrill::OauthRemote::PATH))
    return :oauth if oauth_set

    nil
  end

  def self.spreadsheet_id
    case kind
    when :remote then Lexdrill::Remote.spreadsheet_id
    when :oauth then Lexdrill::OauthRemote.spreadsheet_id
    end
  end

  def self.url
    id = spreadsheet_id
    "https://docs.google.com/spreadsheets/d/#{id}/edit" if id
  end

  def self.newer?(path, other_path)
    File.mtime(path) >= File.mtime(other_path)
  end
  private_class_method :newer?
end
