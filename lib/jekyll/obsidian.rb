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
          puts "Error: obsidian_vault is not set in config.yml"
          exit(1)
        end
        obsidian_files = collect_files(source_dir)
        site.data["obsidian_files"] = obsidian_files.to_json

        backlinks, embeds = build_links(source_dir, obsidian_files, obsidian_files)
        puts "Obsidian links built"

        enable_backlinks = site.config["obsidian_backlinks"]
        if enable_backlinks || enable_backlinks.nil?
          puts "Building backlinks..."
          save_backlinks_to_json(site.dest, backlinks)
          puts "Backlinks built"
        else
          puts "Backlinks disabled"
        end

        enable_embeds = site.config["obsidian_embeds"]
        if enable_embeds || enable_embeds.nil?
          puts "Building embeds..."
          save_embeds_to_json(site.dest, embeds)
          puts "Embeds built"
        else
          puts "Embeds disabled"
        end

        site.config["obsidian_homepage"]

        obsidian_dir = File.join(File.dirname(site.dest), "_includes", "obsidian")
        FileUtils.mkdir_p(obsidian_dir) unless File.directory?(obsidian_dir)

        layouts_dir = File.join(File.dirname(site.dest), "_layouts")
        FileUtils.mkdir_p(layouts_dir) unless File.directory?(layouts_dir)

        project_root = File.expand_path("../..", File.dirname(__FILE__))
        assets_dir = File.join(project_root, "assets")
        puts assets_dir
        explorer = File.join(assets_dir, "includes", "explorer.html")
        fileread = File.join(assets_dir, "includes", "fileread.html")
        note = File.join(assets_dir, "includes", "note.html")
        canvas = File.join(assets_dir, "includes", "canvas.html")

        sidebar = File.join(assets_dir, "includes", "sidebar.html")
        layout = File.join(assets_dir, "layouts", "obsidian.html")

        copy_file_to_dir(explorer, obsidian_dir)
        copy_file_to_dir(fileread, obsidian_dir)
        copy_file_to_dir(note, obsidian_dir)
        copy_file_to_dir(canvas, obsidian_dir)
        copy_file_to_dir(sidebar, obsidian_dir)

        copy_file_to_dir(layout, layouts_dir)
      end

      private

      def copy_file_to_dir(file, dir)
        if File.exist?(file)
          FileUtils.cp(file, dir)
        else
          puts "Error: #{file} does not exist"
          exit
        end
      end

      def excluded_file_exts(filename)
        extensions = [".exe", ".bat", ".sh", ".zip", ".7z", ".stl", ".fbx"]
        is_excluded = extensions.any? { |ext| filename.end_with?(ext) }
        if is_excluded
          puts "Excluded file: #{filename}"
        end
        is_excluded
      end

      def collect_files(rootdir, path = "")
        _files = []
        Dir.entries(rootdir).each do |entry|
          next if entry == "." || entry == ".." || entry.start_with?("_")
          entry_path = File.join(rootdir, entry)
          # puts "file path: #{entry_path}"  # print the path
          _files << if File.directory?(entry_path)
            next if entry.start_with?(".obsidian")
            { name: entry, type: "dir", path: File.join(path, entry),
              children: collect_files(entry_path, File.join(path, entry)) }
          else
            # next unless entry.end_with?(".md", ".canvas")
            next if File.zero?(entry_path) || File.empty?(entry_path)
            { name: entry, type: "file", path: File.join(path, entry) }
          end
        end
        _files
      end

      def build_links(rootdir, _files, root_files, backlinks = {}, embeds = {})
        _files.each do |file|
          if file[:type] == "dir"
            # puts "Directory: #{file[:name]}, Path: #{file[:path]}"
            build_links(rootdir, file[:children], root_files, backlinks, embeds)
          elsif file[:type] == "file"
            entry_path = File.join(rootdir, file[:path])
            next if File.zero?(entry_path) || excluded_file_exts(file[:name])
            if file[:name].end_with?(".md", ".canvas")
              begin
                content = File.read(entry_path)
              rescue Errno::ENOENT
                puts "Error reading file: #{entry_path} - No such file"
                next
              rescue Errno::EACCES
                puts "Error reading file: #{entry_path} - Permission denied"
                next
              end

              # puts "File: #{file[:name]}, Path: #{entry_path}"
              links = content.scan(/\[\[(.*?)\]\]/).flatten

              backlinks[file[:path]] ||= { "backlink_paths" => [] }

              links.each do |link|
                lowercase_link = link.downcase
                matched_entry = find_matching_entry(root_files, lowercase_link)
                if matched_entry
                  unless backlinks[file[:path]]["backlink_paths"].include?(matched_entry[:path])
                    backlinks[file[:path]]["backlink_paths"] << matched_entry[:path]
                  end
                end
              end
            elsif !file[:name].end_with?(".md", ".canvas")
              # Your code for .png and .pdf files here
              if embeds[file[:path]].nil? || embeds[file[:path]]["embed_paths"].nil?
                embeds[file[:path]] = { "embed_paths" => [entry_path] }
              else
                unless embeds[file[:path]]["embed_paths"].include?(entry_path)
                  embeds[file[:path]]["embed_paths"] << entry_path
                end
              end
            end
          else
            puts "Skipping non-markdown file: #{file[:name]}"
          end
        end
        [backlinks, embeds]
      end

      def find_matching_entry(files, lowercase_link)
        files.each do |file|
          if file[:type] == "dir"
            result = find_matching_entry(file[:children], lowercase_link)
            return result if result
          elsif file[:type] == "file" && file[:name].end_with?(".md", ".canvas")
            file_name_without_extension = file[:name].sub(/\.\w+$/, "").downcase
            return file if file_name_without_extension == lowercase_link
          end
        end
        nil
      end

      def save_backlinks_to_json(sitedest, backlinks)
        data_dir = File.join(File.dirname(sitedest), "_data", "obsidian")
        FileUtils.mkdir_p(data_dir) unless File.directory?(data_dir)
        json_file_path = File.join(data_dir, "backlinks.json")

        escaped_backlinks = {}
        # json thinks ' is a special character, so we need to escape it
        backlinks.each do |path, data|
          escaped_path = path.gsub("'", "/:|").gsub('"', "/:|")
          escaped_data = {
            "backlink_paths" => data["backlink_paths"].map { |path| path.gsub("'", "/:|").gsub('"', "/:|") },
          }
          escaped_backlinks[escaped_path] = escaped_data
        end
        File.write(json_file_path, JSON.pretty_generate(escaped_backlinks))
      end

      def save_embeds_to_json(sitedest, embeds)
        data_dir = File.join(File.dirname(sitedest), "_data", "obsidian")
        FileUtils.mkdir_p(data_dir) unless File.directory?(data_dir)
        json_file_path = File.join(data_dir, "embeds.json")
        escaped_embeds = {}
        embeds.each do |path, _|
          escaped_path = path[1..-1].gsub("'", "/:|").gsub('"', "/:|")
          escaped_embeds[escaped_path] = {}
        end
        File.write(json_file_path, JSON.pretty_generate(escaped_embeds))
      end
    end
  end
end
