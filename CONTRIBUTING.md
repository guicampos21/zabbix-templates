# Contributing

## Adding a template

Place each integration in:

```text
templates/<category>/<template-name>/
```

Use lowercase kebab-case directory names. A template directory should contain:

- `README.md` with scope, requirements, installation, configuration,
  compatibility, and troubleshooting instructions
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
ruby scripts/validate_templates.rb
```

The validator checks YAML syntax, Zabbix UUID formatting and uniqueness, and
the presence of required export metadata. A successful offline check does not
replace importing and testing the template in a live Zabbix environment.

## Versioning

Templates are versioned independently. Use release tags in this format:

```text
<template-name>-v<version>
```

For example:

```text
seagate-exos-x-4005-4006-v1.0.4
```
