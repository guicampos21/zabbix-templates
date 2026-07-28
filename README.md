# Zabbix Templates

Monitoring templates for infrastructure, storage, network devices, servers,
and applications.

Each integration is maintained in its own directory with its template,
documentation, changelog, and validation evidence. Unless a template states
otherwise, import the YAML file through **Data collection > Templates > Import**
in a supported Zabbix version.

## Template catalog

| Template | Category | Method | Minimum Zabbix | Version |
|---|---|---|---:|---:|
| [Seagate Exos X 4005/4006 Storage](templates/storage/seagate-exos-x-4005-4006/) | Storage | HTTP/JSON API | 7.0 | 1.0.6 |

## Repository layout

```text
templates/
└── <category>/
    └── <template-name>/
        ├── README.md
        ├── CHANGELOG.md
        ├── template.yaml
        └── validation/
```

Every template directory is self-contained. Read its `README.md` before
importing the template, because requirements, credentials, macros, and supported
hardware vary by integration.

## Versioning

Templates are versioned independently. GitHub Releases belong to this
repository, but each release represents one template. Tags and release names
include the template name to avoid ambiguity:

```text
seagate-exos-x-4005-4006-v1.0.6
```

The importable YAML is attached to its GitHub Release with a versioned filename.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the directory convention and
validation requirements.
