# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased - 2026-02-25

### Added

- Options for `Table` to ignore deleted record and trim `[]const u8`.

## 0.1.0 - 2026-02-24

### Added

- Iteration over opened DBF table.
- Reading fields as zig types:
  - `[]const u8`,
  - `u8`,
  - `u16`,
  - `u32`,
  - `u64`,
  - `f16`,
  - `f32`,
  - `f64`,
  - `f80`,
  - `f128`,
  - `dbf.Date`,
  - `bool`.
