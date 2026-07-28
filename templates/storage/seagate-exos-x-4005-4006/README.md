# Zabbix Template for Seagate Exos X 4005/4006 Storage

Zabbix 7.0+ template for monitoring Seagate Exos storage systems through the
native JSON management API.

The template is designed for Seagate Exos X 4005/4006 systems with Gallium or
Indium controller modules and the following enclosure formats:

- 2U12
- 2U24
- 5U84

The template was validated offline with real API responses from:

- Seagate Exos X 4005-family storage reporting product ID `4865`
- Seagate Exos X 4006

It uses native Zabbix features only: Script items, dependent items, low-level
discovery, trigger prototypes, graph prototypes, value maps, and host macros.
No external scripts or agents are required.

## Requirements

- Zabbix 7.0 or newer
- Network access from the Zabbix server or proxy to the storage management
  controller over HTTP or HTTPS
- A Seagate Exos account with Monitor/read-only permissions and Web/API access
- The native Seagate JSON API enabled on the storage system

> [!IMPORTANT]
> Import and test the template on a non-critical host first. Although it was
> validated against real API captures, a live import and several collection
> cycles are the final compatibility test for your firmware and configuration.

## Installation

1. Download [`template.yaml`](template.yaml).
2. In Zabbix, open **Data collection > Templates**.
3. Select **Import**, choose the downloaded YAML file, and complete the import.
4. Create or select the host that represents the storage array.
5. Link the **Seagate Exos Storage by HTTP** template to the host.
6. Open the host's **Macros** tab and configure the required values:

   | Macro | Example | Description |
   |---|---|---|
   | `{$SEAGATE.API.HOST}` | `192.0.2.10` | Primary controller management IP address or hostname |
   | `{$SEAGATE.API.USERNAME}` | `zabbix` | Monitor/read-only API user |
   | `{$SEAGATE.API.PASSWORD}` | — | API password, stored as a secret-text macro |

7. If necessary, override the connection defaults:

   | Macro | Default | Description |
   |---|---:|---|
   | `{$SEAGATE.API.SCHEME}` | `https` | API scheme: `https` or `http` |
   | `{$SEAGATE.API.PORT}` | `443` | Management API TCP port |
   | `{$SEAGATE.API.HOST.SECONDARY}` | empty | Optional partner-controller management address |

The host does not require an Agent, SNMP, JMX, or IPMI interface for this
template. Collection is performed by Zabbix Script items from the Zabbix server
or the proxy monitoring the host.

## Storage-side preparation

Create a dedicated account in the Seagate management interface with the
Monitor/read-only role and permit Web/API access. Confirm that the Zabbix server
or proxy can reach the selected management address and port.

The template authenticates with the Seagate API using
`SHA-256(username + "_" + password)`, obtains a session key, runs read-only
`show` commands, and logs out. Credentials are supplied through Zabbix macros;
the password macro is defined as `SECRET_TEXT`.

For dual-controller systems, set `{$SEAGATE.API.HOST.SECONDARY}` to enable
login failover. The template tries the secondary address when the primary
address cannot be used.

## First-run verification

Allow two or three polling cycles after linking the template, then check
**Monitoring > Latest data** for the host.

Verify the following:

1. The `API availability raw` item is supported and reports an available API.
2. The five Script master items collect data without method errors:
   - API check
   - Core data
   - Performance data
   - Events and alerts
   - Inventory data
3. Low-level discovery creates the expected controllers, disks, pools, volumes,
   ports, enclosures, and other installed components.
4. Unsupported firmware-specific fields do not affect required monitoring.
5. Trigger thresholds and port policies match the storage configuration.
6. `System latency: Source` identifies either the native 4006 metrics or the
   4005/4865 host-port weighted fallback.

The default collection schedule is:

| Data set | Interval |
|---|---:|
| API availability | 1 minute |
| Core system and hardware state | 2 minutes |
| Performance | 1 minute |
| Events and alerts | 1 minute |
| Inventory | 1 hour |

Intervals can be changed with the `{$SEAGATE.INTERVAL.*}` macros.

## Monitored components

Low-level discovery covers:

- Controllers
- Physical disks
- Disk groups
- Pools
- Volumes
- Storage tiers
- Enclosures
- Field-replaceable units (FRUs)
- Fans and power supplies
- Sensors
- SAS links
- FC, iSCSI, and SAS host ports
- Replication sets

The template monitors health, capacity, utilization, performance, firmware,
system read/write latency, error counters, the common event log, and structured
active alerts when the storage model supports them.

The complete object-level relationship is available in the
[monitoring inventory](MONITORING.md). It lists all fixed items, discovery
rules, item prototypes, fixed triggers, trigger prototypes, fixed graphs, and
graph prototypes, including their Zabbix keys and severities.

| Zabbix object | Fixed | LLD/prototype |
|---|---:|---:|
| Items | 78 | 192 |
| Discovery rules | — | 14 |
| Triggers | 24 | 80 |
| Graphs | 2 | 19 |

## Important configuration macros

| Macro | Default | Purpose |
|---|---:|---|
| `{$SEAGATE.ALERTS.MODE}` | `auto` | Structured Alerts API mode: `auto`, `enabled`, or `disabled` |
| `{$SEAGATE.EVENTS.LAST}` | `100` | Number of recent events requested; maximum 1000 |
| `{$SEAGATE.DATA.TIMEOUT}` | `60s` | Script master-item timeout |
| `{$SEAGATE.ENCLOSURE.EXPECTED}` | `1` | Expected total enclosure count, including the controller enclosure |
| `{$SEAGATE.PORT.DOWN.ENABLED}` | `1` | Enable host-port and SFP alerts |
| `{$SEAGATE.VOLUME.WRITEBACK.REQUIRED}` | `1` | Require write-back policy |
| `{$SEAGATE.REDUNDANCY.REQUIRED}` | `1` | Alert when the system is not redundant |
| `{$SEAGATE.NTP.REQUIRED}` | `0` | Require NTP when set to `1` |
| `{$SEAGATE.CONTROLLER.CPU.WARN}` | `90` | Controller CPU warning threshold, in percent |
| `{$SEAGATE.DISK.TEMP.WARN}` | `50` | Disk temperature warning threshold, in degrees Celsius |
| `{$SEAGATE.DISK.TEMP.CRIT}` | `60` | Disk temperature critical threshold, in degrees Celsius |
| `{$SEAGATE.SSD.LIFE.WARN}` | `10` | SSD remaining-life warning threshold, in percent |

Capacity thresholds for disk groups, pools, and tiers are also exposed as
template macros and can be overridden at host level.

### Excluding intentionally unused ports

Port and SFP alerts support macro contexts. To suppress down alerts for an
intentionally unused port, create a host-level context macro such as:

```text
{$SEAGATE.PORT.DOWN.ENABLED:"A3"} = 0
```

Use the discovered port name shown in Zabbix as the context.

### Enclosure and SAS expansion-port policy

Set `{$SEAGATE.ENCLOSURE.EXPECTED}` to the total number of enclosures that
should be visible:

- `1`: controller enclosure only
- `2`: controller enclosure and one expansion enclosure
- `3`: controller enclosure and two expansion enclosures

The template raises a High-severity problem when the discovered enclosure count
is below this value.

An external `Expansion Port Universal` SAS link is not considered failed only
because its state is `Disconnected`; that state is valid for an unused expansion
port or the last port in an enclosure chain. Health monitoring remains enabled
for all SAS links, while abnormal internal or non-expansion SAS links continue
to generate problems.

## System latency

Version 1.0.6 provides one unified system-latency view while selecting the
collection method supported by the storage model.

### Exos X 4006 native metrics

On Exos X 4006, the template queries these read-only Metrics Framework values:

- `system.read-avg-response-time`
- `system.write-avg-response-time`
- `system.read-max-response-time`
- `system.write-max-response-time`

The collector only runs `query metrics`; it does not call `start metrics` or
`stop metrics`. Bare `N/A` tokens occasionally returned by the API are sanitized
before the response is parsed as JSON.

### 4005/4865 fallback

The tested 4005/4865 API does not expose the Metrics Framework. For that system,
the template derives the host-facing average read and write latency from
`show host-port-statistics`.

It derives the read and write I/O rate of each host port from its cumulative
counters and calculates an I/O-weighted aggregate:

```text
sum(port_latency_us × port_IO_rate) / sum(port_IO_rate)
```

Comparison with native 4006 metrics over clean, aligned intervals produced:

| Measurement | Read | Write |
|---|---:|---:|
| Mean absolute error | approximately 3.05% | approximately 18.16% |
| Pearson correlation | approximately 0.9201 | approximately 0.9605 |

`System latency: Source` shows which method currently feeds the unified items.

### Items and graphs

The system-latency items are:

- `System: Read average response time`
- `System: Write average response time`
- `System: Read maximum response time` — native 4006 only
- `System: Write maximum response time` — native 4006 only
- `System latency: Source`

All system-latency values are stored and displayed in microseconds. The template
includes the `System latency` graph for average read/write time and the
`System maximum latency (4006 native)` graph for native maximum values.

Pool, disk-group, and host-port latency graphs remain available because they
represent different layers of the storage I/O path.

## Hardware and model compatibility

| Scope | Supported target |
|---|---|
| Product family | Seagate Exos X |
| Management/controller models | 4005 and 4006 |
| Controller platforms | Gallium and Indium |
| Enclosure formats | 2U12, 2U24, and 5U84 |

| Feature | 4005/4865 | Exos X 4006 |
|---|:---:|:---:|
| Core system and hardware state | Validated | Validated |
| Controllers and performance | Validated | Validated |
| Disks and predictive counters | Validated | Validated |
| Disk groups, pools, volumes, and tiers | Validated | Validated |
| Enclosures, FRUs, fans, PSUs, and sensors | Validated | Validated |
| SAS link and expander health | Validated | Validated |
| Host ports and SFP data | Validated | Validated |
| Unified system average latency | Weighted fallback | Native metrics |
| System maximum latency | Not exposed by tested API | Native metrics |
| Common Event Log | Validated | Validated |
| Structured active Alerts | Not exposed by tested API | Validated |
| Alert-condition history | Not exposed by tested API | Validated |
| Replication commands | Validated; no active set available | Validated; no active set available |

The template discovers components dynamically and addresses API fields by name,
which makes it tolerant of model differences. Results can still vary with
firmware releases and installed hardware.

## Alert behavior

- Controller and system firmware changes generate Information events.
- Disk error triggers fire when a cumulative counter increases.
- Block-based capacity values are converted to bytes using the reported block
  size.
- Existing component response-time values are converted from microseconds to
  seconds where required; the unified system-latency items remain in
  microseconds.
- Persistent hardware problems use the current component health or status.
- New Warning, Error, and Critical event IDs generate supplemental edge
  notifications.
- Structured active-alert counters are used on supported Exos X 4006 systems.

Native syslog or SNMP event forwarding is still recommended when guaranteed
delivery of every asynchronous storage event is required.

## Troubleshooting

### Authentication fails

- Confirm the username and password at host macro level.
- Confirm the account has Monitor/read-only and Web/API access.
- Check that no unresolved macro is overriding the template value.
- Test both controller addresses if a secondary endpoint is configured.

The login endpoint is validated through a successful HTTP status,
`response-type: Success`, and a non-empty session key. Unlike normal `show`
commands, login does not need to return `return-code: 0`.

### Script items are unsupported

- Confirm that the Zabbix server or assigned proxy can resolve and reach the
  controller address.
- Check `{$SEAGATE.API.SCHEME}` and `{$SEAGATE.API.PORT}`.
- Review the master item's error message and the API method-error items.
- Increase `{$SEAGATE.DATA.TIMEOUT}` if the array answers slowly.

### Expected hardware is not discovered

- Wait for the relevant discovery interval.
- Check the corresponding Script master item for API errors.
- Confirm that the component is visible to the read-only storage account.
- Compare the storage firmware and model with the validated systems above.

## Intentional exclusions

The template does not collect:

- Full `audit-log`, because it was extremely large and truncated in testing
- `workload`, which is mainly intended for tiering and capacity analysis
- `metrics-list` continuously; the 4006 system-latency collector queries the
  required metrics directly
- `fan-modules`, which returned HTTP 400 on the tested 4006; `show fans` supplies
  the required data
- `host-phy-statistics`, which is SAS-host-specific and did not apply to the
  tested configuration
- `remote-systems`, which returned HTTP 400 on the tested 4006

## Validation

Release 1.0.6 passed offline YAML, Zabbix export hierarchy, UUID, graph
reference, latency item, fallback prototype, and JavaScript syntax checks. See
[`validation/v1.0.6.txt`](validation/v1.0.6.txt) for the validation summary and
SHA-256 checksum.

This is structural/offline validation. Importing the template into the target
Zabbix 7.0+ instance remains the final semantic validation.

## Vendor documentation

- [Seagate Exos X 4006 support](https://www.seagate.com/support/disk-arrays/exos-x-4006/)
- [Seagate Exos X 4006 Series Storage Management Guide](https://www.seagate.com/content/dam/seagate/assets/support/disk-arrays/exos-x-4006-2u12/_shared/files/204468700-01-A_4006_SMG.pdf)

## Version

- Template version: `1.0.6`
- Minimum Zabbix version: `7.0`
- Export format: Zabbix `7.0`
