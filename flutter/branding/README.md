# RemoteSupport Brand Profiles

RemoteSupport Technician supports compile-time white-label branding without changing
authentication, ACL, credential handling, RustDesk protocol behavior, or server APIs.

The default profile is `ideal_security/brand.json`.

A brand profile controls presentation only:

- company/product names;
- Technician subtitle and central-auth footer;
- logo/icon asset references;
- primary/accent colors;
- light/dark sidebar colors;
- border accent.

It must **not** change technical identities such as API routes, database schema,
authorization semantics, RustDesk Device IDs, hbbs/hbbr protocol settings, or
security policy.

## Build defines

The Flutter product consumes:

- `REMOTE_SUPPORT_BRAND_ID`
- `REMOTE_SUPPORT_BRAND_COMPANY_NAME`
- `REMOTE_SUPPORT_BRAND_PRODUCT_NAME`
- `REMOTE_SUPPORT_BRAND_TECHNICIAN_SUBTITLE`
- `REMOTE_SUPPORT_BRAND_CENTRAL_AUTH_FOOTER`
- `REMOTE_SUPPORT_BRAND_LOGO_ASSET`
- `REMOTE_SUPPORT_BRAND_ICON_ASSET`
- `REMOTE_SUPPORT_BRAND_PRIMARY_COLOR`
- `REMOTE_SUPPORT_BRAND_PRIMARY_COLOR_50`
- `REMOTE_SUPPORT_BRAND_PRIMARY_COLOR_80`
- `REMOTE_SUPPORT_BRAND_LIGHT_SIDEBAR_COLOR`
- `REMOTE_SUPPORT_BRAND_DARK_SIDEBAR_COLOR`
- `REMOTE_SUPPORT_BRAND_BORDER_ACCENT_COLOR`

Defaults preserve the current IdealSecurity skin.

## Adding a new brand

1. Create a new folder under `flutter/branding/<brand-id>/`.
2. Copy `brand.json` and change only presentation values.
3. Add the brand logo/icon assets under `flutter/assets/` (prefer a namespaced
   folder such as `assets/brands/<brand-id>/`).
4. Build through the governed RemoteSupport brand build script.

Do not fork product logic for branding. A new brand is configuration + assets.
