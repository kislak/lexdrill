# frozen_string_literal: true

RSpec.describe Lexdrill::Browser do
  describe ".open" do
    it "runs the macOS open command" do
      stub_const("RbConfig::CONFIG", RbConfig::CONFIG.merge("host_os" => "darwin23"))
      allow(described_class).to receive(:system)

      described_class.open("https://example.com")

      expect(described_class).to have_received(:system)
        .with("open", "https://example.com", out: File::NULL, err: File::NULL)
    end

    it "runs xdg-open on linux" do
      stub_const("RbConfig::CONFIG", RbConfig::CONFIG.merge("host_os" => "linux"))
      allow(described_class).to receive(:system)

      described_class.open("https://example.com")

      expect(described_class).to have_received(:system)
        .with("xdg-open", "https://example.com", out: File::NULL, err: File::NULL)
    end

    it "runs the windows start command" do
      stub_const("RbConfig::CONFIG", RbConfig::CONFIG.merge("host_os" => "mingw32"))
      allow(described_class).to receive(:system)

      described_class.open("https://example.com")

      expect(described_class).to have_received(:system)
        .with("cmd", "/c", "start", "", "https://example.com", out: File::NULL, err: File::NULL)
    end
  end
end
