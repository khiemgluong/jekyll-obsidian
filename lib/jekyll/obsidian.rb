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
        source_dir = site.config["file_tree_source"] || site.source
        file_tree = generate_file_tree(source_dir)

        site.data["file_tree"] = file_tree
        obsidian_dir = File.join(File.dirname(site.dest), "_obsidian")
        # puts site.dest
        # project_root = File.expand_path("../..", File.dirname(__FILE__))
        # assets_dir = File.join(project_root, "assets")
        # FileUtils.mkdir_p(obsidian_dir) unless File.directory?(obsidian_dir)
        # FileUtils.cp(File.join(assets_dir, "file_tree.js"), obsidian_dir)
        # FileUtils.cp(File.join(assets_dir, "file_tree.css"), obsidian_dir)

        project_root = File.expand_path("../..", File.dirname(__FILE__))
        assets_dir = File.join(project_root, "assets")
        puts assets_dir
        FileUtils.mkdir_p(obsidian_dir) unless File.directory?(obsidian_dir)
        puts "obsidian: " + obsidian_dir

        file_tree_js = File.join(assets_dir, "js", "file_tree.js")
        puts file_tree_js
        file_tree_css = File.join(assets_dir, "css", "file_tree.css")

        if File.exist?(file_tree_js)
          result = FileUtils.cp(file_tree_js, obsidian_dir)
          puts "Copy result for file_tree.js: #{result}"
        else
          puts "Error: #{file_tree_js} does not exist"
          exit
        end

        if File.exist?(file_tree_css)
          result = FileUtils.cp(file_tree_css, obsidian_dir)
          puts "Copy result for file_tree.css: #{result}"
        else
          puts "Error: #{file_tree_css} does not exist"
          puts site.dest
        end
      end

      private

      def generate_file_tree(dir)
        tree = []
        Dir.entries(dir).each do |entry|
          next if entry == "." || entry == ".." || entry.start_with?("_")
          path = File.join(dir, entry)
          tree << if File.directory?(path)
            {name: entry, type: "directory", children: generate_file_tree(path)}
          else
            {name: entry, type: "file"}
          end
        end
        tree
      end
    end
  end
end
