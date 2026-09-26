# Technician identity propagation

Validated: 2026-09-26

## Scope

This document records the IdealSecurity Technician customization that propagates the authenticated RemoteSupport technician display name to the Agent-side RustDesk connection manager.

It is intentionally separate from the frozen rollback tag:

`technician-rc2-validated-2026-09-24`

The frozen tag must not be moved or reinterpreted.

## Validated source

Development branch:

`fix/technician-ui-name-overflow-r1`

Validated commits:

- `a8a5b52d` — `fix: propagate technician display name to remote session`
- `7a6f85608` — `fix: improve technician identity layout`

Release-integration branch:

`release/technician-rc3-app-r1`

Validated HEAD:

`7a6f85608b63bc829a6f12bcebfa22b5bd11bd01`

## Problem

The Agent-side connection manager rendered `client.name`, which came from `LoginRequest.my_name`.

Before this change, `LoginRequest.my_name` was resolved from RustDesk/local machine identity, so the remote Agent could display a workstation name such as:

```text
Prtg
(306076110)
```

instead of the authenticated RemoteSupport technician identity.

## Implemented flow

```text
TechnicianCentralSession.identity.displayName
        ↓
flutter/lib/common.dart
mainSetLocalOption("technician-display-name")
        ↓
LocalConfig
        ↓
src/client.rs
LoginRequest.my_name
        ↓
Agent
client.name
```

The existing RustDesk protocol field is reused.

The RustDesk peer/device ID is unchanged.

The display-name field is not authorization. Existing central ACL/credential resolution and RustDesk authentication remain authoritative.

## Files changed

`flutter/lib/common.dart`

- Technician edition writes the authenticated display name to `technician-display-name` before launching the session.

`src/client.rs`

- normal RustDesk display-name resolution remains as fallback;
- a non-empty `technician-display-name` overrides the presentation value sent as `LoginRequest.my_name`.

`flutter/lib/common/widgets/address_book.dart`

- technician display name gets its own line;
- username is displayed as `@username`;
- constrained width uses ellipsis;
- full display name remains available through tooltip.

## Build prerequisites

Required submodule:

`libs/hbb_common`

Validated commit:

`7e1c392c62d39c364127307cd408421dd5f8cfb0`

Flutter Rust Bridge codegen:

`1.80.1`

cargo-expand:

`1.0.95`

Bridge command used:

```powershell
flutter_rust_bridge_codegen `
  --rust-input .\src\flutter_ffi.rs `
  --dart-output .\flutter\lib\generated_bridge.dart `
  --c-output .\flutter\macos\Runner\bridge_generated.h
```

Generated bridge files are build artifacts, not intended functional source changes.

## Validated builds

Rust:

```powershell
cargo build --release --features flutter --lib
```

Result:

`PASS`

Flutter Windows:

```powershell
flutter build windows --release --no-pub `
  --dart-define=REMOTE_SUPPORT_API_BASE_URL=https://srv-remote-support.tailc83419.ts.net/
```

Result:

`PASS`

## Native artifact checkpoint

`librustdesk.dll`

Size:

`36353680` bytes

SHA256:

`2CF174EABEE0C7C8C12F598943D65FC3B33A6A25CC3C491FF448A50BCC0447F7`

The DLL in the Flutter Release output had the same SHA256.

## Functional validation

Observed Agent-side result after connecting with the authenticated Technician:

```text
Leandro Dornelles
(306076110)
Conectado ...
```

Result:

`TECHNICIAN_IDENTITY_PROPAGATION=PASS`

## Packaging boundary

This source/runtime candidate is not the same artifact as the previously validated RC3 1.0.4 installer.

Before installer promotion:

1. package the complete runtime from this release branch;
2. record runtime file inventory;
3. calculate ZIP and `rustdesk.exe` hashes;
4. retain the DLL hash above;
5. update the installer build gate;
6. build a new installer version;
7. validate on a clean workstation;
8. rerun package secret scan.

