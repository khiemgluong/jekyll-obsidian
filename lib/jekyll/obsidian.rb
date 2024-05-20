# lib/jekyll/obsidian.rb
# frozen_string_literal: true

require "jekyll"
require "json"

require_relative "obsidian/version"

module Jekyll
  module Obsidian
    class FileTreeGenerator < Jekyll::Generator
      safe true
      priority :lowest

      def generate(site)
        source_dir = site.config["obsidian_vault"] || site.source
        obsidian_files = collect_files(source_dir)
        site.data["obsidian_files"] = obsidian_files
        site.data["obsidian_files_json"] = obsidian_files.to_json
        obsidian_dir = File.join(File.dirname(site.dest), "_includes", "_obsidian")

        project_root = File.expand_path("../..", File.dirname(__FILE__))
        assets_dir = File.join(project_root, "assets")
        puts assets_dir
        FileUtils.mkdir_p(obsidian_dir) unless File.directory?(obsidian_dir)
        puts "obsidian: " + obsidian_dir

        file_tree_js = File.join(assets_dir, "js", "file_tree.js")
        puts file_tree_js
        file_tree_css = File.join(assets_dir, "css", "file_tree.css")
        file_tree_html = File.join(assets_dir, "widgets", "file_tree.html")

        if File.exist?(file_tree_html)
          result = FileUtils.cp(file_tree_html, obsidian_dir)
          puts "Copy result for file_tree.html: #{result}"
        else
          puts "Error: #{file_tree_html} does not exist"
          exit
        end

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

      def collect_files(dir, path = "")
        _files = []
        Dir.entries(dir).each do |entry|
          next if entry == "." || entry == ".." || entry.start_with?("_")
          entry_path = File.join(dir, entry)
          puts "file path: #{entry_path}"  # print the path
          _files << if File.directory?(entry_path)
            next if entry.start_with?("assets") || entry.start_with?(".obsidian")
            { name: entry, type: "dir", path: File.join(path, entry), children: collect_files(entry_path, File.join(path, entry)) }
          else
            next unless entry.end_with?(".md", ".canvas")
            next if File.zero?(entry_path) || File.empty?(entry_path)
            { name: entry, type: "file", path: File.join(path, entry) }
          end
        end
        _files
      end
    end
  end
end
