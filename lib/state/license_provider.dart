import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';

enum LicenseTier {
  free,
  premium,
}

enum LicensePlan {
  none,
  monthly,
  annual,
  lifetime,
}

enum PdfFeature {
  merge,
  split,
  compressBasic,
  compressAdvanced,
  rotate,
  pageManagerBasic,
  pageManagerAdvanced,
  extractPages,
  deletePages,
  pdfToImages,
  imagesToPdf,
  pdfToWord,
  pdfToExcel,
  pdfToPowerPoint,
  advancedEditing,
  watermark,
  securityPassword,
  pdfComparison,
  ocr,
  batchProcessing,
  metadataBatch,
}

class LicenseState {
  final LicenseTier tier;
  final LicensePlan plan;
  final String? licenseKey;
  final DateTime? expiryDate;
  final bool isTrialActive;

  const LicenseState({
    this.tier = LicenseTier.free,
    this.plan = LicensePlan.none,
    this.licenseKey,
    this.expiryDate,
    this.isTrialActive = false,
  });

  // All features and models are 100% free and unlocked!
  bool get isPremium => true;

  bool canAccess(PdfFeature feature) => true;

  LicenseState copyWith({
    LicenseTier? tier,
    LicensePlan? plan,
    String? licenseKey,
    DateTime? expiryDate,
    bool? isTrialActive,
  }) {
    return LicenseState(
      tier: tier ?? this.tier,
      plan: plan ?? this.plan,
      licenseKey: licenseKey ?? this.licenseKey,
      expiryDate: expiryDate ?? this.expiryDate,
      isTrialActive: isTrialActive ?? this.isTrialActive,
    );
  }
}

class LicenseNotifier extends Notifier<LicenseState> {
  static const _tierKey = 'license_tier';
  static const _planKey = 'license_plan';
  static const _licenseKey = 'license_key';

  @override
  LicenseState build() {
    _loadStoredLicense();
    return const LicenseState();
  }

  Future<void> _loadStoredLicense() async {
    try {
      final tierStr = await AppDatabase.instance.getPreference(_tierKey);
      final planStr = await AppDatabase.instance.getPreference(_planKey);
      final keyStr = await AppDatabase.instance.getPreference(_licenseKey);

      if (tierStr == 'premium') {
        LicensePlan plan = LicensePlan.annual;
        if (planStr == 'monthly') plan = LicensePlan.monthly;
        if (planStr == 'lifetime') plan = LicensePlan.lifetime;

        state = state.copyWith(
          tier: LicenseTier.premium,
          plan: plan,
          licenseKey: keyStr ?? 'READNEXT-LIFETIME-ALL',
        );
      }
    } catch (e) {
      debugPrint('Error loading license preference: $e');
    }
  }

  Future<bool> activateLicense(String key, {LicensePlan plan = LicensePlan.annual}) async {
    final clean = key.trim().toUpperCase();
    if (clean.isEmpty) return false;

    // Accepts format READNEXT-XXXX-XXXX or valid promo/VIP code
    final isValid = clean.startsWith('READNEXT') || clean.contains('PRO') || clean.contains('VIP') || clean.length >= 8;
    if (isValid) {
      state = state.copyWith(
        tier: LicenseTier.premium,
        plan: plan,
        licenseKey: clean,
      );
      await AppDatabase.instance.setPreference(_tierKey, 'premium');
      await AppDatabase.instance.setPreference(_planKey, plan.name);
      await AppDatabase.instance.setPreference(_licenseKey, clean);
      return true;
    }
    return false;
  }

  Future<void> setDemoPremium(bool enable) async {
    if (enable) {
      state = state.copyWith(
        tier: LicenseTier.premium,
        plan: LicensePlan.lifetime,
        licenseKey: 'DEMO-PREMIUM-UNLOCKED',
      );
      await AppDatabase.instance.setPreference(_tierKey, 'premium');
      await AppDatabase.instance.setPreference(_planKey, LicensePlan.lifetime.name);
      await AppDatabase.instance.setPreference(_licenseKey, 'DEMO-PREMIUM-UNLOCKED');
    } else {
      state = const LicenseState(tier: LicenseTier.free, plan: LicensePlan.none);
      await AppDatabase.instance.setPreference(_tierKey, 'free');
      await AppDatabase.instance.setPreference(_planKey, LicensePlan.none.name);
      await AppDatabase.instance.setPreference(_licenseKey, '');
    }
  }

  Future<void> setFreeTier() async {
    await setDemoPremium(false);
  }
}

final licenseProvider = NotifierProvider<LicenseNotifier, LicenseState>(() {
  return LicenseNotifier();
});
