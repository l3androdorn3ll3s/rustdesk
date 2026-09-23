import 'package:flutter/material.dart';

/// Compile-time white-label profile for RemoteSupport.
///
/// A brand can be selected without changing product logic by supplying
/// --dart-define values at build time. Defaults preserve the current
/// IdealSecurity identity.
class RemoteSupportBrand {
  RemoteSupportBrand._();

  static const id = String.fromEnvironment(
    'REMOTE_SUPPORT_BRAND_ID',
    defaultValue: 'ideal_security',
  );

  static const companyName = String.fromEnvironment(
    'REMOTE_SUPPORT_BRAND_COMPANY_NAME',
    defaultValue: 'IdealSecurity',
  );

  static const productName = String.fromEnvironment(
    'REMOTE_SUPPORT_BRAND_PRODUCT_NAME',
    defaultValue: 'IdealSecurity Remote Support',
  );

  static const technicianSubtitle = String.fromEnvironment(
    'REMOTE_SUPPORT_BRAND_TECHNICIAN_SUBTITLE',
    defaultValue: 'Acesso do técnico',
  );

  static const centralAuthFooter = String.fromEnvironment(
    'REMOTE_SUPPORT_BRAND_CENTRAL_AUTH_FOOTER',
    defaultValue: 'A autenticação é realizada pelo servidor central.',
  );

  static const logoAsset = String.fromEnvironment(
    'REMOTE_SUPPORT_BRAND_LOGO_ASSET',
    defaultValue: 'assets/brand_logo.png',
  );

  static const iconAsset = String.fromEnvironment(
    'REMOTE_SUPPORT_BRAND_ICON_ASSET',
    defaultValue: 'assets/icon.png',
  );

  static const primaryColorValue = int.fromEnvironment(
    'REMOTE_SUPPORT_BRAND_PRIMARY_COLOR',
    defaultValue: 0xFFDC9919,
  );

  static const primaryColor50Value = int.fromEnvironment(
    'REMOTE_SUPPORT_BRAND_PRIMARY_COLOR_50',
    defaultValue: 0x77DC9919,
  );

  static const primaryColor80Value = int.fromEnvironment(
    'REMOTE_SUPPORT_BRAND_PRIMARY_COLOR_80',
    defaultValue: 0xAADC9919,
  );

  static const lightSidebarColorValue = int.fromEnvironment(
    'REMOTE_SUPPORT_BRAND_LIGHT_SIDEBAR_COLOR',
    defaultValue: 0xFFE8E1D5,
  );

  static const darkSidebarColorValue = int.fromEnvironment(
    'REMOTE_SUPPORT_BRAND_DARK_SIDEBAR_COLOR',
    defaultValue: 0xFF252117,
  );

  static const borderAccentColorValue = int.fromEnvironment(
    'REMOTE_SUPPORT_BRAND_BORDER_ACCENT_COLOR',
    defaultValue: 0xFFB97C10,
  );

  static const primaryColor = Color(primaryColorValue);
  static const primaryColor50 = Color(primaryColor50Value);
  static const primaryColor80 = Color(primaryColor80Value);
  static const lightSidebarColor = Color(lightSidebarColorValue);
  static const darkSidebarColor = Color(darkSidebarColorValue);
  static const borderAccentColor = Color(borderAccentColorValue);
}
