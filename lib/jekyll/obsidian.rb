# lib/jekyll/obsidian.rb
# frozen_string_literal: true
require "jekyll"

require_relative "obsidian/version"

module Jekyll
  module Obsidian
    class FileTreeGenerator < Jekyll::Generator
      safe true
      priority :lowest

      def generate(site)
        source_dir = site.config['file_tree_source'] || site.source
        file_tree = generate_file_tree(source_dir)

        site.data['file_tree'] = file_tree
      end

      private

      def generate_file_tree(dir)
        tree = []
        Dir.entries(dir).each do |entry|
          next if entry == '.' || entry == '..' || entry.start_with?('_')
          path = File.join(dir, entry)
          if File.directory?(path)
            tree << { name: entry, type: 'directory', children: generate_file_tree(path) }
          else
            tree << { name: entry, type: 'file' }
          end
        end
        tree
      end
    end
  end
end
