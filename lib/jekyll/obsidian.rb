# lib/jekyll/obsidian.rb
# frozen_string_literal: true

require "jekyll"
require "json"
require "fileutils"

require_relative "obsidian/version"

module Jekyll
  module Obsidian
    def self.collect_files(rootdir, path = "", counts = {dirs: 0, files: 0, size: 0})
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

          file_name = entry
          file_name += "note" if File.extname(entry) == ".md"
          entry = file_name
          file_size = File.size(entry_path)
          counts[:files] += 1
          counts[:size] += File.size(entry_path)
          {name: entry, type: "file", path: File.join(path, entry), size: file_size}
        end
      end
      root_files_
    end

    def self.build_links(rootdir, root_files_, root_files, backlinks = {}, embeds = {})
      root_files_.each do |file|
        if file[:type] == "dir"
          build_links(rootdir, file[:children], root_files, backlinks, embeds)
        elsif file[:type] == "file"
          entry_path = File.join(rootdir, file[:path])
          next if File.zero?(entry_path) || Obsidian.excluded_file_exts(file[:name])
          if file[:name].end_with?(".mdnote", ".canvas")
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
          elsif !file[:name].end_with?(".mdnote", ".canvas")
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

    def self.find_matching_entry(files, lowercase_link)
      stripped_link = lowercase_link.sub(/\|.*$/, "").sub(/#.*$/, "")
      files.each do |file|
        if file[:type] == "dir"
          result = find_matching_entry(file[:children], lowercase_link)
          return result if result
        elsif file[:type] == "file" && file[:name].end_with?(".mdnote", ".canvas")
          file_name_without_extension = file[:name].sub(/\.\w+$/, "").downcase
          return file if file_name_without_extension == stripped_link
        end
      end
      nil
    end

    def self.excluded_file_exts(filename)
      extensions = [".exe", ".bat", ".sh", ".zip", ".7z", ".stl", ".fbx"]
      is_excluded = extensions.any? { |ext| filename.end_with?(ext) }
      if is_excluded
        puts "Excluded file: #{filename}"
      end
      is_excluded
    end

    # ------------------------ Ruby Hash object formatters ----------------------- #
    def self.escape_backlinks(backlinks)
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
      JSON.pretty_generate(escaped_backlinks.to_json)
    end

    def self.escape_embeds(embeds)
      escaped_embeds = {}
      embeds.each do |path, _|
        escaped_path = escape_path(path)
        escaped_embeds[escaped_path] = {}
      end
      JSON.pretty_generate(escaped_embeds.to_json)
    end

    def self.escape_path(path)
      escaped_path = path.gsub("'", "/:|").gsub('"', "/:|")
      (escaped_path[0] == "/") ? escaped_path.slice(1..-1) : escaped_path
    end

    # ---------------------------------------------------------------------------- #
    #                               FileTreeGenerator                              #
    # ---------------------------------------------------------------------------- #
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
        site.config["obsidian_homepage"]

        # --------------------------------- site data -------------------------------- #
        site.data["obsidian"] = {} unless site.data["obsidian"]

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
    end

    # ---------------------------------------------------------------------------- #
    #                           POST_WRITE HOOK REGISTER                           #
    # ---------------------------------------------------------------------------- #
    Jekyll::Hooks.register :site, :post_write do |site|
      vault = site.config["obsidian_vault"]
      vault_path = File.join(site.dest, vault)
      Dir.glob(File.join(vault_path, "**", "*.md")).each do |md_file|
        new_file_path = md_file.sub(/\.md$/, ".mdnote")
        File.rename(md_file, new_file_path)
      end
      data_dir = File.join(File.dirname(site.dest), "_data", "obsidian")
      FileUtils.mkdir_p(data_dir) unless File.directory?(data_dir)
      enable_backlinks = site.config["obsidian_backlinks"]
      enable_embeds = site.config["obsidian_embeds"]

      counts = {dirs: 0, files: 0, size: 0}
      obsidian_files = Obsidian.collect_files(vault, "", counts)
      vault_data_json = File.join(data_dir, "vault_data.json")
      File.write(vault_data_json, JSON.pretty_generate(counts.to_json))

      vault_files_json = File.join(data_dir, "vault_files.json")
      File.write(vault_files_json, JSON.pretty_generate(obsidian_files.to_json))

      vault_path = File.join(site.dest, vault)
      backlinks, embeds = Obsidian.build_links(vault_path, obsidian_files, obsidian_files)

      if enable_backlinks || enable_backlinks.nil?
        backlinks_json = File.join(data_dir, "backlinks.json")
        File.write(backlinks_json, Obsidian.escape_backlinks(backlinks))
        puts "Backlinks built."
      else
        puts "Backlinks disabled"
      end

      if enable_embeds || enable_embeds.nil?
        embeds_json = File.join(data_dir, "embeds.json")
        File.write(embeds_json, Obsidian.escape_embeds(embeds))
        puts "Embeds built."
      else
        puts "Embeds disabled"
      end
    end

  end
end
