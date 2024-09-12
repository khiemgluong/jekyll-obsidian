# frozen_string_literal: true

require_relative "lib/jekyll/obsidian/version"

Gem::Specification.new do |spec|
  spec.name = "jekyll-obsidian"
  spec.version = Jekyll::Obsidian::VERSION
  spec.authors = ["Khiem Luong"]
  spec.email = ["khiemgluong@gmail.com"]

  spec.summary = "Obsidian integration for Jekyll"
  spec.description = "Jekyll site implementation of obsidian as close to how it looks in the app"
  spec.homepage = "https://khiemgluong.github.io"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/khiemgluong/jekyll-obsidian/"
  spec.metadata["changelog_uri"] = "https://github.com/khiemgluong/jekyll-obsidian/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "jekyll", "~> 4.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
