# Contributing

## Adding a template

Place each integration in:

```text
templates/<category>/template_<template_name>/<zabbix-version>/
```

Use the upstream-compatible `template_` prefix and characters accepted by the
Zabbix community repository. Each version directory must contain:

- `README.md` with scope, requirements, installation, configuration,
  macros, metrics, triggers, graphs, dashboards, release history, author,
  compatibility, validation summary, and troubleshooting
- exactly one importable YAML export named `template_<template_name>.yaml`

Do not add separate changelogs, monitoring inventories, or validation reports
to a template directory. Consolidate that information in the version README so
the version folder remains directly suitable for upstream submission.

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
seagate-exos-x-4005-4006-v1.1.2
```

Each GitHub Release should represent one template, use the same template-scoped
tag, summarize only that template's changes, and attach its importable YAML with
a versioned filename.

## Upstream submissions

Prepare a stable copy under the matching category in a fork of
`zabbix/community-templates`. The upstream version folder should contain only
the YAML export and its `README.md`. Keep this repository as the source of truth
and use the fork only to submit pull requests. All contributed files must be
MIT-licensed and the YAML must import without errors into the declared Zabbix
version.
