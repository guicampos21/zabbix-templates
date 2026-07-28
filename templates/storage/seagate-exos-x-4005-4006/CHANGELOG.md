# Changelog

All notable changes to the Seagate Exos X 4005/4006 Storage template are
documented here.

## 1.0.6

- Added unified system read and write average latency items.
- Added native system average and maximum latency collection for Exos X 4006
  through the read-only Metrics Framework.
- Added an I/O-weighted host-port fallback for average read and write latency on
  the tested 4005/4865 API, where the Metrics Framework is unavailable.
- Added `System latency` and `System maximum latency (4006 native)` graphs.
- Added `System latency: Source` to identify whether native metrics or the
  weighted fallback is feeding the unified items.
- Sanitized bare `N/A` tokens returned by the Metrics Framework before JSON
  parsing.
- Corrected the Zabbix 7.0 export hierarchy by moving fixed graphs to the
  top-level `zabbix_export.graphs` section. This supersedes the 1.0.5 export,
  which Zabbix rejected because the graphs were nested below the template.

## 1.0.4

- Excluded a disconnected state by itself from the generic status trigger for
  external `Expansion Port Universal` SAS links.
- Kept health triggers enabled for every SAS link.
- Kept abnormal-status alerts enabled for internal and non-expansion SAS links.
- Added `{$SEAGATE.ENCLOSURE.EXPECTED}`, with a default value of `1`.
- Added a High-severity trigger when the discovered enclosure count is lower
  than the configured expected count.
