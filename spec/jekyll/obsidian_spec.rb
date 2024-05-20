# frozen_string_literal: true
require "spec_helper"

RSpec.describe Jekyll::Obsidian do
  it "has a version number" do
    expect(Jekyll::Obsidian::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
# spec/jekyll/obsidian_spec.rb

require "spec_helper"

RSpec.describe Jekyll::Obsidian::FileTreeGenerator do
  it "generates a file tree" do
    site = double("site")
    allow(site).to receive(:config).and_return({ "file_tree_source" => "source_dir" })
    allow(site).to receive(:source).and_return("source_dir")
    allow(site).to receive(:data).and_return({})

    generator = Jekyll::Obsidian::FileTreeGenerator.new
    expect { generator.generate(site) }.not_to raise_error
  end
end
