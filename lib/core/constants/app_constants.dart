import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'ReadNext';
  static const String appTagline = 'Smart PDF Reader & Utility Suite';
  static const String developerName = 'Complex Innovators';
  static const String appVersion = '1.0.0';
  static const String appLogo = 'assets/images/logo.png';
  static const String appLogoIcon = 'assets/images/logo_icon.png';

  // Freemium Pricing
  static const String monthlyPrice = '₹199';
  static const String annualPrice = '₹1,499';
  static const String lifetimePrice = '₹3,999';

  // Zoom limits
  static const double minZoom = 0.5; // 50%
  static const double maxZoom = 5.0; // 500%
  static const double defaultZoom = 1.0; // 100%
  static const double zoomStep = 0.25;

  static const List<double> zoomPresets = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
    2.5,
    3.0,
    4.0,
    5.0,
  ];

  // Annotation Colors
  static const List<Color> highlightColors = [
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF81C784), // Green
    Color(0xFF64B5F6), // Blue
    Color(0xFFF48FB1), // Pink
    Color(0xFFFFB74D), // Orange
    Color(0xFFCE93D8), // Purple
  ];

  static const List<Color> inkColors = [
    Color(0xFF000000), // Black
    Color(0xFFD32F2F), // Red
    Color(0xFF1976D2), // Blue
    Color(0xFF388E3C), // Green
    Color(0xFFF57C00), // Orange
    Color(0xFF7B1FA2), // Purple
    Color(0xFFFFFFFF), // White
  ];

  // Stamp presets
  static const List<String> stampPresets = [
    'APPROVED',
    'DRAFT',
    'CONFIDENTIAL',
    'REJECTED',
    'FINAL',
    'REVIEWED',
  ];
}
