import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../state/license_provider.dart';

class PremiumUpgradeDialog extends ConsumerStatefulWidget {
  const PremiumUpgradeDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PremiumUpgradeDialog(),
    );
  }

  @override
  ConsumerState<PremiumUpgradeDialog> createState() => _PremiumUpgradeDialogState();
}

class _PremiumUpgradeDialogState extends ConsumerState<PremiumUpgradeDialog> {
  final TextEditingController _licenseController = TextEditingController();
  LicensePlan _selectedPlan = LicensePlan.annual;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final license = ref.watch(licenseProvider);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.verified, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ReadNext — 100% Free & Unlocked',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'All tools, OCR models, and Office converters are completely free with zero subscriptions.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Pricing Tier Selector Cards
              Row(
                children: [
                  Expanded(
                    child: _buildPlanCard(
                      plan: LicensePlan.monthly,
                      title: 'Monthly',
                      price: AppConstants.monthlyPrice,
                      subtitle: 'Billed monthly',
                      isPopular: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPlanCard(
                      plan: LicensePlan.annual,
                      title: 'Annual',
                      price: AppConstants.annualPrice,
                      subtitle: '₹125 / month',
                      isPopular: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPlanCard(
                      plan: LicensePlan.lifetime,
                      title: 'Lifetime',
                      price: AppConstants.lifetimePrice,
                      subtitle: 'Pay once, own forever',
                      isPopular: false,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Feature Matrix Highlights
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow('OCR for Scanned PDFs (English, Hindi, Marathi)', true),
                    _buildFeatureRow('Convert to Word (.docx), Excel (.xlsx), PowerPoint (.pptx)', true),
                    _buildFeatureRow('Simultaneous Batch Processing Queue', true),
                    _buildFeatureRow('Text & Image Watermark Tools', true),
                    _buildFeatureRow('Password Protection & Permission Restrictions', true),
                    _buildFeatureRow('Visual & Textual PDF Document Comparison', true),
                    _buildFeatureRow('Merge, Split, Basic Compress, Rotate & Images (Free forever)', true, isFree: true),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // License Key Entry
              TextField(
                controller: _licenseController,
                decoration: InputDecoration(
                  labelText: 'Have a License Key?',
                  hintText: 'e.g. READNEXT-PRO-2026-VIP',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  errorText: _errorMessage,
                  suffixIcon: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: _isLoading ? null : _handleActivateKey,
                    child: const Text('Activate'),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Demo Testing Quick Toggle & Current Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status: ${license.isPremium ? "Active (Premium Tier)" : "Free Tier"}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: license.isPremium ? Colors.green : theme.colorScheme.primary,
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: Icon(license.isPremium ? Icons.lock_reset : Icons.bolt, size: 18),
                    label: Text(license.isPremium ? 'Switch to Free Mode' : 'Instant Demo Premium (1-Click)'),
                    onPressed: () async {
                      if (license.isPremium) {
                        await ref.read(licenseProvider.notifier).setFreeTier();
                      } else {
                        await ref.read(licenseProvider.notifier).setDemoPremium(true);
                      }
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required LicensePlan plan,
    required String title,
    required String price,
    required String subtitle,
    required bool isPopular,
  }) {
    final isSelected = _selectedPlan == plan;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedPlan = plan),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2.2 : 1,
          ),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.cardColor,
        ),
        child: Column(
          children: [
            if (isPopular)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text, bool isChecked, {bool isFree = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isFree ? Icons.check_circle_outline : Icons.check_circle,
            color: isFree ? Colors.blueGrey : Colors.green,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isFree ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleActivateKey() async {
    final key = _licenseController.text.trim();
    if (key.isEmpty) {
      setState(() => _errorMessage = 'Please enter a valid license key');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(licenseProvider.notifier).activateLicense(key, plan: _selectedPlan);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 ReadNext Premium activated successfully!')),
        );
        Navigator.of(context).pop();
      } else {
        setState(() => _errorMessage = 'Invalid key. Try entering READNEXT-VIP-2026 or click Instant Demo.');
      }
    }
  }
}
