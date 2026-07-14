# frozen_string_literal: true

RSpec.describe Lexdrill::RemoteTarget do
  around do |example|
    Dir.mktmpdir("lexdrill-remote-target-spec") do |dir|
      @dir = dir
      example.run
    end
  end

  before do
    stub_const("Lexdrill::Remote::PATH", File.join(@dir, ".drill.remote"))
    stub_const("Lexdrill::OauthRemote::PATH", File.join(@dir, ".drill.oauth-remote"))
  end

  describe ".kind/.spreadsheet_id/.url" do
    it "is nil/nil/nil when neither is configured" do
      expect(described_class.kind).to be_nil
      expect(described_class.spreadsheet_id).to be_nil
      expect(described_class.url).to be_nil
    end

    it "uses remote (service account) when only it is configured" do
      Lexdrill::Remote.set("https://docs.google.com/spreadsheets/d/remote-id/edit")

      expect(described_class.kind).to eq(:remote)
      expect(described_class.spreadsheet_id).to eq("remote-id")
      expect(described_class.url).to eq("https://docs.google.com/spreadsheets/d/remote-id/edit")
    end

    it "uses oauth when only it is configured" do
      Lexdrill::OauthRemote.set("https://docs.google.com/spreadsheets/d/oauth-id/edit")

      expect(described_class.kind).to eq(:oauth)
      expect(described_class.spreadsheet_id).to eq("oauth-id")
    end

    it "prefers whichever was configured more recently when both are set" do
      Lexdrill::OauthRemote.set("https://docs.google.com/spreadsheets/d/oauth-id/edit")
      File.utime(Time.now - 10, Time.now - 10, Lexdrill::OauthRemote::PATH)
      Lexdrill::Remote.set("https://docs.google.com/spreadsheets/d/remote-id/edit")

      expect(described_class.kind).to eq(:remote)
      expect(described_class.spreadsheet_id).to eq("remote-id")

      File.utime(Time.now - 10, Time.now - 10, Lexdrill::Remote::PATH)
      Lexdrill::OauthRemote.set("https://docs.google.com/spreadsheets/d/oauth-id-2/edit")

      expect(described_class.kind).to eq(:oauth)
      expect(described_class.spreadsheet_id).to eq("oauth-id-2")
    end
  end
end
