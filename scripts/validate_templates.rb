#!/usr/bin/env ruby

require "digest"
require "yaml"

template_files = Dir.glob("templates/**/template.yaml").sort
abort "No template.yaml files found" if template_files.empty?

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

template_files.each do |path|
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

  checksum = Digest::SHA256.file(path).hexdigest
  puts "#{path}: PASS"
  puts "  Zabbix export version: #{export['version']}"
  puts "  UUID fields: #{uuids.length}"
  puts "  SHA-256: #{checksum}"
end

abort errors.join("\n") unless errors.empty?

puts "All templates passed offline validation."
