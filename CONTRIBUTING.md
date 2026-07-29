# Contributing

## Adding a template

Place each integration in:

```text
templates/<category>/<template-name>/
```

Use lowercase kebab-case directory names. A template directory should contain:

- `README.md` with scope, requirements, installation, configuration,
  compatibility, and troubleshooting instructions
- `MONITORING.md` generated from the YAML with the complete item, trigger, graph,
  and low-level discovery inventory
- `template.yaml` containing the importable Zabbix export
- `CHANGELOG.md` with changes grouped by template version
- `validation/` for checksums or validation reports, when available

Optional integration-specific assets such as scripts, MIBs, or media files
should remain inside the same template directory.

## Catalog

Add every new integration to the table in the repository `README.md`. Include
its category, collection method, minimum supported Zabbix version, and current
template version.

## Validation

Before submitting a change, run:

```bash
ruby scripts/generate_template_inventory.rb
ruby scripts/validate_templates.rb
```

The inventory generator refreshes the object-level documentation. The automated
checks verify YAML syntax, Zabbix UUID formatting and uniqueness, required
export metadata, and whether the generated inventory is current. A successful
offline check does not replace importing and testing the template in a live
Zabbix environment.

## Versioning

Templates are versioned independently. Use release tags in this format:

```text
<template-name>-v<version>
```

For example:

```text
seagate-exos-x-4005-4006-v1.0.7
```

Each GitHub Release should represent one template, use the same template-scoped
tag, summarize only that template's changes, and attach its importable YAML with
a versioned filename.
