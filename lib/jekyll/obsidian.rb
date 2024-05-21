# lib/jekyll/obsidian.rb
# frozen_string_literal: true

require "jekyll"
require "json"
require "fileutils"

require_relative "obsidian/version"

module Jekyll
  module Obsidian
    class FileTreeGenerator < Jekyll::Generator
      safe true
      priority :lowest

      def generate(site)
        source_dir = site.config["obsidian_vault"] || site.source
        if source_dir.nil?
          puts "\e[31mError: obsidian_vault is not set in the config.yml\e[0m"
          exit(1)
        end
        obsidian_files = collect_files(source_dir)
        backlinks = build_backlinks(source_dir, obsidian_files, obsidian_files)
        # save_backlinks_to_json(site.dest, backlinks)

        site.data["obsidian_files"] = obsidian_files
        site.data["obsidian_files_json"] = obsidian_files.to_json

        obsidian_dir = File.join(File.dirname(site.dest), "_includes", "_obsidian")
        FileUtils.mkdir_p(obsidian_dir) unless File.directory?(obsidian_dir)

        layouts_dir = File.join(File.dirname(site.dest), "_layouts")
        FileUtils.mkdir_p(layouts_dir) unless File.directory?(layouts_dir)

        project_root = File.expand_path("../..", File.dirname(__FILE__))
        assets_dir = File.join(project_root, "assets")
        puts assets_dir
        puts "obsidian: " + obsidian_dir

        file_read = File.join(assets_dir, "includes", "file_read.html")
        file_tree = File.join(assets_dir, "includes", "file_tree.html")
        layouts = File.join(assets_dir, "layouts", "obsidian.html")

        if File.exist?(file_read)
          result = FileUtils.cp(file_read, obsidian_dir)
          puts "Copy result for file_read.html: #{result}"
        else
          puts "Error: #{file_read} does not exist"
          exit
        end

        if File.exist?(file_tree)
          result = FileUtils.cp(file_tree, obsidian_dir)
          puts "Copy result for file_tree.js: #{result}"
        else
          puts "Error: #{file_tree} does not exist"
          exit
        end

        if File.exist?(layouts)
          result = FileUtils.cp(layouts, layouts_dir)
          puts "Copy result for layouts.css: #{result}"
        else
          puts "Error: #{layouts} does not exist"
          puts site.dest
        end
      end

      private

      def collect_files(rootdir, path = "")
        _files = []
        Dir.entries(rootdir).each do |entry|
          next if entry == "." || entry == ".." || entry.start_with?("_")
          entry_path = File.join(rootdir, entry)
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

      def build_backlinks(rootdir, _files, root_files)
        _files.each do |file|
          if file[:type] == "dir"
            puts "Directory: #{file[:name]}, Path: #{file[:path]}"
            build_backlinks(rootdir, file[:children], root_files)
          elsif file[:type] == "file" && (file[:name].end_with?(".md") || file[:name].end_with?(".canvas"))
            entry_path = File.join(rootdir, file[:path])
            next if File.zero?(entry_path)

            begin
              content = File.read(entry_path)
            rescue Errno::ENOENT
              puts "Error reading file: #{entry_path} - No such file or directory"
              next
            rescue Errno::EACCES
              puts "Error reading file: #{entry_path} - Permission denied"
              next
            end

            puts "File: #{file[:name]}, Path: #{entry_path}"
            links = content.scan(/\[\[(.*?)\]\]/).flatten

            links.each do |link|
              lowercase_link = link.downcase
              matched_entry = find_matching_entry(root_files, lowercase_link)
              if matched_entry
                puts "Backlink: #{link}, Path: #{File.join(rootdir, matched_entry[:path])}"
              else
                puts "Backlink: #{link}, No matching file found"
              end
            end
          else
            puts "Skipping non-markdown file: #{file[:name]}"
          end
        end
      end

      def find_matching_entry(files, lowercase_link)
        files.each do |file|
          if file[:type] == "dir"
            result = find_matching_entry(file[:children], lowercase_link)
            return result if result
          elsif file[:type] == "file" && (file[:name].end_with?(".md") || file[:name].end_with?(".canvas"))
            file_name_without_extension = file[:name].sub(/\.\w+$/, "").downcase
            return file if file_name_without_extension == lowercase_link
          end
        end
        nil
      end
    end
  end
end
