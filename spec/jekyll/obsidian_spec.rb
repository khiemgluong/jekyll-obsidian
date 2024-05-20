# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Jekyll::Obsidian do
  it "has a version number" do
    expect(Jekyll::Obsidian::VERSION).not_to be nil
  end

  # Commented out for now as it's designed to fail
  # it "does something useful" do
  #   expect(false).to eq(true)
  # end
end

RSpec.describe Jekyll::Obsidian::FileTreeGenerator do
  it "generates a file tree" do
    Dir.mktmpdir do |dir|
      site = double("site")
      allow(site).to receive(:config).and_return({"file_tree_source" => dir})
      allow(site).to receive(:source).and_return(dir)
      allow(site).to receive(:data).and_return({})
      allow(site).to receive(:dest).and_return(dir)

      generator = Jekyll::Obsidian::FileTreeGenerator.new
      expect { generator.generate(site) }.not_to raise_error
    end
  end
end
