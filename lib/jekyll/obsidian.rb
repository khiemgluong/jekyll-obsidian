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
        # -------------------------------- site config ------------------------------- #
        vault = site.config["obsidian_vault"] || site.source
        if vault.nil?
          puts "Error: obsidian_vault is not set in config.yml"
          exit(1)
        end
        enable_backlinks = site.config["obsidian_backlinks"]
        enable_embeds = site.config["obsidian_embeds"]

        # --------------------------------- site data -------------------------------- #
        site.data["obsidian"] = {} unless site.data["obsidian"]

        counts = {dirs: 0, files: 0, size: 0}
        obsidian_files = collect_files(vault, "", counts)
        puts "Total dir count: #{counts[:dirs]}"
        puts "Total file count: #{counts[:files]}"
        puts "Total size of files: #{counts[:size]} B"
        site.data["obsidian_counts"] = counts.to_json

        site.data["obsidian"]["vault_files"] = obsidian_files.to_json

        backlinks, embeds = build_links(vault, obsidian_files, obsidian_files)
        puts "Obsidian links built"

        if enable_backlinks || enable_backlinks.nil?
          site.data["obsidian"]["backlinks"] = escape_backlinks(backlinks).to_json
          puts "Backlinks built."
        else
          puts "Backlinks disabled"
        end

        if enable_embeds || enable_embeds.nil?
          site.data["obsidian"]["embeds"] = escape_embeds(embeds).to_json
          # save_embeds_to_json(site.dest, embeds)
          puts "Embeds built."
        else
          puts "Embeds disabled"
        end

        site.config["obsidian_homepage"]

        obsidian_dir = File.join(File.dirname(site.dest), "_includes", "obsidian")
        FileUtils.mkdir_p(obsidian_dir) unless File.directory?(obsidian_dir)

        layouts_dir = File.join(File.dirname(site.dest), "_layouts")
        FileUtils.mkdir_p(layouts_dir) unless File.directory?(layouts_dir)

        scss_dir = File.join(File.dirname(site.dest), "assets", "obsidian")
        FileUtils.mkdir_p(scss_dir) unless File.directory?(scss_dir)

        partials_dir = File.join(File.dirname(site.dest), "_sass", "obsidian")
        FileUtils.mkdir_p(partials_dir) unless File.directory?(partials_dir)

        project_root = File.expand_path("../..", File.dirname(__FILE__))
        plugin_dir = File.join(project_root, "assets")
        # puts plugin_dir

        main_scss = File.join(plugin_dir, "css", "obsidian.scss")
        copy_file_to_dir(main_scss, scss_dir)

        copy_files_from_dir(File.join(plugin_dir, "css", "partials"), partials_dir)

        layout = File.join(plugin_dir, "layouts", "obsidian.html")
        copy_file_to_dir(layout, layouts_dir, true)

        copy_files_from_dir(File.join(plugin_dir, "includes"), obsidian_dir, true)
      end

      private

      def copy_file_to_dir(file, dir, overwrite = false)
        if File.exist?(file)
          destination_file = File.join(dir, File.basename(file))

          if !overwrite && File.exist?(destination_file)
            puts "#{File.basename(file)} currently exists"
          else
            FileUtils.cp(file, dir)
            puts "#{File.basename(file)} copied over"
          end
        else
          puts "Error: #{file} does not exist"
          exit
        end
      end

      def copy_files_from_dir(source_dir, destination_dir, overwrite = false)
        Dir.glob(File.join(source_dir, "*")).each do |file_path|
          next if File.directory?(file_path)
          copy_file_to_dir(file_path, destination_dir, overwrite)
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

      # ------------------------ Ruby Hash object generators ----------------------- #
      def collect_files(rootdir, path = "", counts = {dirs: 0, files: 0, size: 0})
        root_files_ = []
        Dir.entries(rootdir).each do |entry|
          next if entry.start_with?(".", "_")
          entry_path = File.join(rootdir, entry)
          root_files_ << if File.directory?(entry_path)
            next if entry.start_with?(".obsidian")
            counts[:dirs] += 1
            {name: entry, type: "dir", path: File.join(path, entry),
             children: collect_files(entry_path, File.join(path, entry), counts)}
          else
            next if File.zero?(entry_path) || File.empty?(entry_path)
            counts[:files] += 1
            counts[:size] += File.size(entry_path)
            {name: entry, type: "file", path: File.join(path, entry), size: File.size(entry_path)}
          end
        end
        root_files_
      end

      def build_links(rootdir, root_files_, root_files, backlinks = {}, embeds = {})
        root_files_.each do |file|
          if file[:type] == "dir"
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

              links = content.scan(/\[\[(.*?)\]\]/).flatten

              backlinks[file[:path]] ||= {"backlink_paths" => []}

              links.each do |link|
                lowercase_link = link.downcase
                matched_entry = find_matching_entry(root_files, lowercase_link)
                if matched_entry
                  unless matched_entry[:path] == file[:path] ||
                      backlinks[file[:path]]["backlink_paths"].include?(matched_entry[:path])
                    backlinks[file[:path]]["backlink_paths"] << matched_entry[:path]
                  end
                end
              end
            elsif !file[:name].end_with?(".md", ".canvas")
              if embeds[file[:path]].nil? || embeds[file[:path]]["embed_paths"].nil?
                embeds[file[:path]] = {"embed_paths" => [entry_path]}
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
        stripped_link = lowercase_link.sub(/\|.*$/, "").sub(/#.*$/, "")
        files.each do |file|
          if file[:type] == "dir"
            result = find_matching_entry(file[:children], lowercase_link)
            return result if result
          elsif file[:type] == "file" && file[:name].end_with?(".md", ".canvas")
            file_name_without_extension = file[:name].sub(/\.\w+$/, "").downcase
            return file if file_name_without_extension == stripped_link
          end
        end
        nil
      end

      # ------------------------ Ruby Hash object formatters ----------------------- #
      def escape_backlinks(backlinks)
        escaped_backlinks = {}
        backlinks.each do |path, data|
          escaped_path = escape_path(path)
          escaped_data = {
            "backlink_paths" => data["backlink_paths"].map do |path|
              escape_path(path)
            end
          }
          escaped_backlinks[escaped_path] = escaped_data
        end
        escaped_backlinks
      end

      def escape_embeds(embeds)
        escaped_embeds = {}
        embeds.each do |path, _|
          escaped_path = escape_path(path)
          escaped_embeds[escaped_path] = {}
        end
        escaped_embeds
      end

      def escape_path(path)
        escaped_path = path.gsub("'", "/:|").gsub('"', "/:|")
        (escaped_path[0] == "/") ? escaped_path.slice(1..-1) : escaped_path
      end

      # ------------------- Write Ruby Hash objects to JSON files ------------------ #
      def save_backlinks_to_json(sitedest, backlinks)
        data_dir = File.join(File.dirname(sitedest), "_data", "obsidian")
        FileUtils.mkdir_p(data_dir) unless File.directory?(data_dir)
        json_file_path = File.join(data_dir, "backlinks.json")
        escaped_backlinks = escape_backlinks(backlinks)
        File.write(json_file_path, JSON.pretty_generate(escaped_backlinks))
      end

      def save_embeds_to_json(sitedest, embeds)
        data_dir = File.join(File.dirname(sitedest), "_data", "obsidian")
        FileUtils.mkdir_p(data_dir) unless File.directory?(data_dir)
        json_file_path = File.join(data_dir, "embeds.json")
        escaped_embeds = escape_embeds(embeds)
        File.write(json_file_path, JSON.pretty_generate(escaped_embeds))
      end
    end
  end
end
