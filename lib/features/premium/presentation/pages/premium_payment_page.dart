import 'package:flutter/material.dart';

import '../../data/premium_access_controller.dart';
import '../../data/premium_entitlement_repository.dart';
import '../../domain/premium_models.dart';

enum PaymentMethod { googlePlay, upi, card, wallet }

class PremiumPaymentPage extends StatefulWidget {
  final PremiumPlan plan;
  final bool allowLocalDevelopmentSimulation;

  const PremiumPaymentPage({
    super.key,
    required this.plan,
    this.allowLocalDevelopmentSimulation = false,
  });

  @override
  State<PremiumPaymentPage> createState() => _PremiumPaymentPageState();
}

class _PremiumPaymentPageState extends State<PremiumPaymentPage> {
  final _entitlementRepository = PremiumEntitlementRepository();
  PaymentMethod _method = PaymentMethod.googlePlay;
  bool _processing = false;

  Future<void> _completeDevelopmentPayment() async {
    setState(() => _processing = true);
    final result = widget.allowLocalDevelopmentSimulation
        ? PremiumVerificationResult(
            verified: true,
            features: allPremiumFeatures,
            message: 'Local widget-test verification completed.',
          )
        : await _entitlementRepository.verifyDevelopmentPurchase(
            userId: 'demo-user',
            features: allPremiumFeatures,
            provider: _providerName(_method),
            productId: widget.plan.id,
          );
    if (!mounted) return;
    setState(() => _processing = false);
    if (!result.verified) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }
    PremiumAccessController.instance.applyVerifiedEntitlement(result.features);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.verified, color: Colors.green, size: 42),
        title: const Text('Premium unlocked'),
        content: const Text(
          'Development entitlement applied. Production must unlock only after '
          'backend verification of the store or payment-provider receipt.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  String _providerName(PaymentMethod method) => switch (method) {
    PaymentMethod.googlePlay => 'google_play',
    PaymentMethod.upi => 'upi',
    PaymentMethod.card => 'card',
    PaymentMethod.wallet => 'wallet',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: Text(widget.plan.name),
              subtitle: const Text(
                'Includes AI Hair, AI Beard, and AI Nail premium features',
              ),
              trailing: Text(
                widget.plan.priceLabel,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Choose payment method',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          RadioGroup<PaymentMethod>(
            groupValue: _method,
            onChanged: (value) {
              if (value != null) setState(() => _method = value);
            },
            child: const Column(
              children: [
                _PaymentTile(
                  value: PaymentMethod.googlePlay,
                  icon: Icons.play_circle_outline,
                  title: 'Google Play Billing',
                  subtitle: 'Recommended for Play Store digital subscriptions',
                ),
                _PaymentTile(
                  value: PaymentMethod.upi,
                  icon: Icons.qr_code_2,
                  title: 'UPI',
                  subtitle: 'Availability depends on store and regional policy',
                ),
                _PaymentTile(
                  value: PaymentMethod.card,
                  icon: Icons.credit_card,
                  title: 'Credit / Debit Card',
                  subtitle: 'Use through an approved payment provider',
                ),
                _PaymentTile(
                  value: PaymentMethod.wallet,
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Wallet',
                  subtitle: 'Provider availability varies by country',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            color: Color(0xfffff4df),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Development mode: no money will be charged. This button '
                'simulates a backend-verified entitlement for UI testing.',
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _processing ? null : _completeDevelopmentPayment,
            icon: _processing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_open_outlined),
            label: Text(
              _processing ? 'Verifying...' : 'Complete development payment',
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentMethod value;
  final IconData icon;
  final String title;
  final String subtitle;

  const _PaymentTile({
    required this.value,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: RadioListTile<PaymentMethod>(
        value: value,
        secondary: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
