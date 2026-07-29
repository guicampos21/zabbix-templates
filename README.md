# Zabbix Templates

Monitoring templates for infrastructure, storage, network devices, servers,
and applications.

Each integration follows the Zabbix community directory convention: a
`template_` directory, a folder for each supported Zabbix major version, and an
importable YAML export whose name starts with `template_`. Each version folder
contains only the importable template and its complete README.

## Template catalog

| Template | Category | Method | Minimum Zabbix | Version |
|---|---|---|---:|---:|
| [Seagate Exos X 4005/4006 Storage](templates/storage/template_seagate_exos_x_4005_4006/7.0/) | Storage | HTTP/JSON API | 7.0 | 1.1.0 |

## Repository layout

```text
templates/
└── <category>/
    └── template_<template_name>/
        └── <zabbix-version>/
            ├── README.md
            └── template_<template_name>.yaml
```

Every template directory is self-contained. Read its `README.md` before
importing the template, because requirements, credentials, macros, and supported
hardware vary by integration.

## Versioning

Templates are versioned independently. GitHub Releases belong to this
repository, but each release represents one template. Tags and release names
include the template name to avoid ambiguity:

```text
seagate-exos-x-4005-4006-v1.1.0
```

The importable YAML is attached to its GitHub Release with a versioned filename.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the directory convention and
validation requirements.

Stable templates may also be submitted unchanged to the
[Zabbix community templates repository](https://github.com/zabbix/community-templates).
This repository remains the development source and retains template-scoped Git
history and releases.

## License

This repository is licensed under the [MIT License](LICENSE), matching the
license required for Zabbix community template contributions.
