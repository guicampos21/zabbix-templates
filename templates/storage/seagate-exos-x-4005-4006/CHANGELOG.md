# Changelog

All notable changes to the Seagate Exos X 4005/4006 Storage template are
documented here.

## 1.0.4

- Excluded a disconnected state by itself from the generic status trigger for
  external `Expansion Port Universal` SAS links.
- Kept health triggers enabled for every SAS link.
- Kept abnormal-status alerts enabled for internal and non-expansion SAS links.
- Added `{$SEAGATE.ENCLOSURE.EXPECTED}`, with a default value of `1`.
- Added a High-severity trigger when the discovered enclosure count is lower
  than the configured expected count.
