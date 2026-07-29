#!/usr/bin/env ruby

require "digest"
require "yaml"

template_files = Dir.glob("templates/**/[0-9]*/*.yaml").sort
abort "No versioned template YAML files found" if template_files.empty?

errors = []

def collect_uuids(value, uuids = [])
  case value
  when Hash
    value.each do |key, child|
      uuids << child.to_s if key.to_s == "uuid"
      collect_uuids(child, uuids)
    end
  when Array
    value.each { |child| collect_uuids(child, uuids) }
  end
  uuids
end

def collect_named_objects(value, key, objects = [])
  case value
  when Hash
    objects.concat(value[key]) if value[key].is_a?(Array)
    value.each_value { |child| collect_named_objects(child, key, objects) }
  when Array
    value.each { |child| collect_named_objects(child, key, objects) }
  end
  objects
end

template_files.each do |path|
  version_directory = File.basename(File.dirname(path))
  template_directory = File.basename(File.dirname(File.dirname(path)))
  filename = File.basename(path)

  unless version_directory.match?(/\A\d+\.\d+\z/)
    errors << "#{path}: parent directory must be a Zabbix major version"
  end
  unless template_directory.match?(/\Atemplate_[.a-zA-Z0-9()_-]+\z/)
    errors << "#{path}: template directory does not follow the upstream naming convention"
  end
  unless filename.match?(/\Atemplate_[.a-zA-Z0-9()_-]+\.yaml\z/)
    errors << "#{path}: YAML filename does not follow the upstream naming convention"
  end
  yaml_siblings = Dir.glob(File.join(File.dirname(path), "*.{yaml,yml,json,xml}"))
  if yaml_siblings.length != 1
    errors << "#{path}: version directory must contain exactly one template export"
  end
  expected_entries = ["README.md", filename].sort
  actual_entries = Dir.children(File.dirname(path)).sort
  unless actual_entries == expected_entries
    errors << "#{path}: version directory must contain only README.md and #{filename}"
  end

  begin
    document = YAML.load_file(path)
  rescue StandardError => e
    errors << "#{path}: YAML parse failed: #{e.message}"
    next
  end

  export = document.is_a?(Hash) ? document["zabbix_export"] : nil
  unless export.is_a?(Hash) && export["version"] && export["templates"].is_a?(Array)
    errors << "#{path}: missing required zabbix_export metadata"
    next
  end

  uuids = collect_uuids(document)
  invalid = uuids.reject { |uuid| uuid.match?(/\A[0-9a-f]{32}\z/i) }
  duplicates = uuids.tally.select { |_uuid, count| count > 1 }

  errors << "#{path}: invalid UUIDs: #{invalid.join(', ')}" unless invalid.empty?
  errors << "#{path}: duplicate UUIDs: #{duplicates.keys.join(', ')}" unless duplicates.empty?

  template = export["templates"].first
  item_keys = collect_named_objects(template, "items").filter_map { |item| item["key"] }
  item_keys.concat(
    collect_named_objects(template, "item_prototypes").filter_map { |item| item["key"] }
  )
  graph_names = collect_named_objects(export, "graphs").filter_map { |graph| graph["name"] }
  graph_names.concat(
    collect_named_objects(template, "graph_prototypes").filter_map { |graph| graph["name"] }
  )

  collect_named_objects(template, "widgets").each do |widget|
    Array(widget["fields"]).each do |field|
      reference = field["value"]
      next unless reference.is_a?(Hash)

      if field["type"] == "ITEM" && !item_keys.include?(reference["key"])
        errors << "#{path}: dashboard references unknown item key #{reference['key']}"
      elsif %w[GRAPH GRAPH_PROTOTYPE].include?(field["type"]) &&
            !graph_names.include?(reference["name"])
        errors << "#{path}: dashboard references unknown graph #{reference['name']}"
      end
    end
  end

  checksum = Digest::SHA256.file(path).hexdigest
  puts "#{path}: PASS"
  puts "  Zabbix export version: #{export['version']}"
  puts "  UUID fields: #{uuids.length}"
  puts "  SHA-256: #{checksum}"
end

abort errors.join("\n") unless errors.empty?

puts "All templates passed offline validation."
