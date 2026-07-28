#!/usr/bin/env ruby

require "yaml"

ROOT = File.expand_path("..", __dir__)
TEMPLATE_PATH = File.join(
  ROOT,
  "templates/storage/seagate-exos-x-4005-4006/template.yaml"
)
OUTPUT_PATH = File.join(
  ROOT,
  "templates/storage/seagate-exos-x-4005-4006/MONITORING.md"
)

def array(value)
  value.is_a?(Array) ? value : []
end

def escape(value)
  value.to_s.gsub("|", "\\|").gsub("\n", "<br>")
end

def code(value)
  "`#{escape(value).gsub('`', '\\`')}`"
end

def item_type(item)
  item["type"] || "ZABBIX_PASSIVE"
end

def value_type(item)
  item["value_type"] || "UNSIGNED"
end

def component(item)
  tag = array(item["tags"]).find { |entry| entry["tag"] == "component" }
  tag ? tag["value"] : "other"
end

def heading(value)
  { "sas" => "SAS" }.fetch(value, value.capitalize)
end

def priority(trigger)
  trigger["priority"] || "NOT_CLASSIFIED"
end

def graph_item_keys(graph)
  array(graph["graph_items"]).filter_map { |entry| entry.dig("item", "key") }
end

document = YAML.load_file(TEMPLATE_PATH)
export = document.fetch("zabbix_export")
template = export.fetch("templates").first
fixed_items = array(template["items"])
discoveries = array(template["discovery_rules"])
fixed_graphs = array(export["graphs"])

fixed_triggers = fixed_items.flat_map do |item|
  array(item["triggers"]).map { |trigger| [trigger, item] }
end

prototype_items = discoveries.sum { |rule| array(rule["item_prototypes"]).length }
prototype_triggers = discoveries.sum do |rule|
  array(rule["item_prototypes"]).sum do |item|
    array(item["trigger_prototypes"]).length
  end
end
prototype_graphs = discoveries.sum { |rule| array(rule["graph_prototypes"]).length }
version = template.dig("vendor", "version")

lines = []
lines << "# Monitoring inventory"
lines << ""
lines << "Complete inventory generated from `template.yaml` version #{version}."
lines << "It includes fixed objects and low-level discovery (LLD) prototypes."
lines << ""
lines << "> [!NOTE]"
lines << "> Script master items and dependent/raw transport items are included because"
lines << "> they are part of the template, even when they primarily support collection."
lines << "> Trigger source identifies the item prototype that owns the trigger in the"
lines << "> Zabbix export; an expression can reference additional items."
lines << ""
lines << "## Summary"
lines << ""
lines << "| Object | Count |"
lines << "|---|---:|"
lines << "| Fixed items | #{fixed_items.length} |"
lines << "| Discovery rules | #{discoveries.length} |"
lines << "| Item prototypes | #{prototype_items} |"
lines << "| Fixed triggers | #{fixed_triggers.length} |"
lines << "| Trigger prototypes | #{prototype_triggers} |"
lines << "| Fixed graphs | #{fixed_graphs.length} |"
lines << "| Graph prototypes | #{prototype_graphs} |"
lines << ""
lines << "## Fixed items"

fixed_items.group_by { |item| component(item) }.sort.each do |group, items|
  lines << ""
  lines << "### #{escape(heading(group))}"
  lines << ""
  lines << "| Item | Key | Type | Value type |"
  lines << "|---|---|---|---|"
  items.each do |item|
    lines << "| #{escape(item['name'])} | #{code(item['key'])} | " \
             "#{code(item_type(item))} | #{code(value_type(item))} |"
  end
end

lines << ""
lines << "## Fixed triggers"
lines << ""
lines << "| Trigger | Severity | Source item |"
lines << "|---|---|---|"
fixed_triggers.each do |trigger, item|
  lines << "| #{escape(trigger['name'])} | #{code(priority(trigger))} | " \
           "#{escape(item['name'])} |"
end

lines << ""
lines << "## Fixed graphs"
lines << ""
lines << "| Graph | Item keys |"
lines << "|---|---|"
fixed_graphs.each do |graph|
  keys = graph_item_keys(graph).map { |key| code(key) }.join("<br>")
  lines << "| #{escape(graph['name'])} | #{keys} |"
end

lines << ""
lines << "## Low-level discovery"

discoveries.each do |rule|
  item_prototypes = array(rule["item_prototypes"])
  trigger_prototypes = item_prototypes.flat_map do |item|
    array(item["trigger_prototypes"]).map { |trigger| [trigger, item] }
  end
  graph_prototypes = array(rule["graph_prototypes"])

  lines << ""
  lines << "### #{escape(rule['name'])}"
  lines << ""
  lines << "- Discovery key: #{code(rule['key'])}"
  lines << "- Discovery type: #{code(item_type(rule))}"
  lines << "- Item prototypes: #{item_prototypes.length}"
  lines << "- Trigger prototypes: #{trigger_prototypes.length}"
  lines << "- Graph prototypes: #{graph_prototypes.length}"
  lines << ""
  lines << "#### Item prototypes"
  lines << ""
  lines << "| Item prototype | Key | Type | Value type |"
  lines << "|---|---|---|---|"
  item_prototypes.each do |item|
    lines << "| #{escape(item['name'])} | #{code(item['key'])} | " \
             "#{code(item_type(item))} | #{code(value_type(item))} |"
  end

  lines << ""
  lines << "#### Trigger prototypes"
  lines << ""
  if trigger_prototypes.empty?
    lines << "No trigger prototypes."
  else
    lines << "| Trigger prototype | Severity | Source item prototype |"
    lines << "|---|---|---|"
    trigger_prototypes.each do |trigger, item|
      lines << "| #{escape(trigger['name'])} | #{code(priority(trigger))} | " \
               "#{escape(item['name'])} |"
    end
  end

  lines << ""
  lines << "#### Graph prototypes"
  lines << ""
  if graph_prototypes.empty?
    lines << "No graph prototypes."
  else
    lines << "| Graph prototype | Item prototype keys |"
    lines << "|---|---|"
    graph_prototypes.each do |graph|
      keys = graph_item_keys(graph).map { |key| code(key) }.join("<br>")
      lines << "| #{escape(graph['name'])} | #{keys} |"
    end
  end
end

content = "#{lines.join("\n")}\n"

if ARGV.include?("--check")
  abort "#{OUTPUT_PATH} is not up to date" unless File.exist?(OUTPUT_PATH)
  abort "#{OUTPUT_PATH} is not up to date" unless File.read(OUTPUT_PATH) == content
  puts "#{OUTPUT_PATH}: up to date"
else
  File.write(OUTPUT_PATH, content)
  puts "Generated #{OUTPUT_PATH}"
end
