import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/premium_access_controller.dart';
import '../../data/premium_entitlement_repository.dart';
import '../../domain/premium_models.dart';

enum PaymentMethod { upi, card, netBanking, paypal }

class PremiumPaymentPage extends StatefulWidget {
  final Set<PremiumFeature> selectedFeatures;
  final int totalAmount;
  final bool allowLocalDevelopmentSimulation;

  const PremiumPaymentPage({
    super.key,
    required this.selectedFeatures,
    required this.totalAmount,
    this.allowLocalDevelopmentSimulation = false,
  });

  @override
  State<PremiumPaymentPage> createState() => _PremiumPaymentPageState();
}

class _PremiumPaymentPageState extends State<PremiumPaymentPage> {
  final _entitlementRepository = PremiumEntitlementRepository();
  final _upiController = TextEditingController(text: 'username@upi');
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _bankSearchController = TextEditingController();
  PaymentMethod _method = PaymentMethod.upi;
  bool _processing = false;
  bool _saveCard = true;
  String? _selectedBank;

  @override
  void dispose() {
    _upiController.dispose();
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _bankSearchController.dispose();
    super.dispose();
  }

  Future<void> _completeDevelopmentPayment() async {
    setState(() => _processing = true);
    final result = widget.allowLocalDevelopmentSimulation
        ? PremiumVerificationResult(
            verified: true,
            features: widget.selectedFeatures,
            message: 'Local checkout verification completed.',
          )
        : await _entitlementRepository.verifyDevelopmentPurchase(
            userId: 'demo-user',
            features: widget.selectedFeatures,
            provider: _providerName(_method),
            productId: 'selected_features_monthly',
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
        title: const Text('Payment successful'),
        content: const Text(
          'Premium features unlocked for this development session.',
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
    PaymentMethod.upi => 'upi',
    PaymentMethod.card => 'card',
    PaymentMethod.netBanking => 'net_banking',
    PaymentMethod.paypal => 'paypal',
  };

  Future<void> _launchUpiIntent(String label) async {
    final uri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': 'salon@upi',
        'pn': 'The Salon App',
        'am': widget.totalAmount.toString(),
        'cu': 'INR',
        'tn': 'Premium features checkout',
      },
    );
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No UPI app opened for $label')),
      );
    }
  }

  Future<void> _launchPayPalCheckout() async {
    final uri = Uri.https('www.paypal.com', '/checkoutnow', {
      'amount': widget.totalAmount.toString(),
      'currency': 'INR',
    });
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open PayPal checkout')),
      );
    }
  }

  void _showCouponSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Have a coupon?', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Coupon code',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = formatRupees(widget.totalAmount);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: Text('3/3')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OrderSummaryCard(
            selectedFeatures: widget.selectedFeatures,
            totalAmount: widget.totalAmount,
            onCouponTap: _showCouponSheet,
          ),
          const SizedBox(height: 16),
          Text('Pay Using', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _PaymentAccordionTile(
            selected: _method == PaymentMethod.upi,
            title: 'UPI - Recommended',
            icon: Icons.qr_code_2,
            onTap: () => setState(() => _method = PaymentMethod.upi),
            child: _UpiSection(
              controller: _upiController,
              onAnyUpiTap: () => _launchUpiIntent('any UPI app'),
              onAppTap: _launchUpiIntent,
            ),
          ),
          _PaymentAccordionTile(
            selected: _method == PaymentMethod.card,
            title: 'Cards',
            icon: Icons.credit_card,
            onTap: () => setState(() => _method = PaymentMethod.card),
            child: _CardSection(
              cardController: _cardController,
              expiryController: _expiryController,
              cvvController: _cvvController,
              saveCard: _saveCard,
              onSaveCardChanged: (value) => setState(() => _saveCard = value),
            ),
          ),
          _PaymentAccordionTile(
            selected: _method == PaymentMethod.netBanking,
            title: 'Net Banking',
            icon: Icons.account_balance,
            onTap: () => setState(() => _method = PaymentMethod.netBanking),
            child: _NetBankingSection(
              controller: _bankSearchController,
              selectedBank: _selectedBank,
              onBankSelected: (bank) => setState(() {
                _selectedBank = bank;
                _bankSearchController.text = bank;
              }),
            ),
          ),
          _PaymentAccordionTile(
            selected: _method == PaymentMethod.paypal,
            title: 'PayPal',
            icon: Icons.public,
            onTap: () => setState(() => _method = PaymentMethod.paypal),
            child: _PayPalSection(onPayPalTap: _launchPayPalCheckout),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _processing ? null : _completeDevelopmentPayment,
            icon: _processing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_outline),
            label: Text(_processing ? 'Verifying...' : 'Pay $amount Securely'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.lock_outline, size: 16),
              SizedBox(width: 6),
              Text('Razorpay Secure - 256-bit encrypted'),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final Set<PremiumFeature> selectedFeatures;
  final int totalAmount;
  final VoidCallback onCouponTap;

  const _OrderSummaryCard({
    required this.selectedFeatures,
    required this.totalAmount,
    required this.onCouponTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Summary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            for (final feature in selectedFeatures)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(feature.label)),
                    Text(formatRupees(feature.monthlyPrice)),
                  ],
                ),
              ),
            const Divider(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${formatRupees(totalAmount)} / month',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onCouponTap,
                child: const Text('Have coupon?'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentAccordionTile extends StatelessWidget {
  final bool selected;
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Widget child;

  const _PaymentAccordionTile({
    required this.selected,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  const SizedBox(width: 10),
                  Icon(icon),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: child,
                ),
                crossFadeState: selected
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpiSection extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAnyUpiTap;
  final ValueChanged<String> onAppTap;

  const _UpiSection({
    required this.controller,
    required this.onAnyUpiTap,
    required this.onAppTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'UPI ID',
            hintText: 'username@paytm',
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffd7e2ea)),
          ),
          child: ListTile(
            onTap: onAnyUpiTap,
            leading: const Icon(Icons.send_to_mobile_outlined),
            title: const Text('Pay by any UPI App'),
            subtitle: const Text('Opens installed UPI apps on this phone'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PayAppButton(
                label: 'GPay',
                onTap: () => onAppTap('GPay'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PayAppButton(
                label: 'PhonePe',
                onTap: () => onAppTap('PhonePe'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PayAppButton(
                label: 'Paytm',
                onTap: () => onAppTap('Paytm'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CardSection extends StatelessWidget {
  final TextEditingController cardController;
  final TextEditingController expiryController;
  final TextEditingController cvvController;
  final bool saveCard;
  final ValueChanged<bool> onSaveCardChanged;

  const _CardSection({
    required this.cardController,
    required this.expiryController,
    required this.cvvController,
    required this.saveCard,
    required this.onSaveCardChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: cardController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Card Number',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: expiryController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'MM/YY',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: cvvController,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'CVV',
                ),
              ),
            ),
          ],
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: saveCard,
          onChanged: (value) => onSaveCardChanged(value ?? false),
          title: const Text('Save card for next time'),
        ),
      ],
    );
  }
}

class _NetBankingSection extends StatelessWidget {
  final TextEditingController controller;
  final String? selectedBank;
  final ValueChanged<String> onBankSelected;

  const _NetBankingSection({
    required this.controller,
    required this.selectedBank,
    required this.onBankSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
            labelText: 'Search bank',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final bank in const ['SBI', 'HDFC', 'ICICI', 'Axis'])
              _BankChip(
                label: bank,
                selected: selectedBank == bank,
                onSelected: () => onBankSelected(bank),
              ),
          ],
        ),
      ],
    );
  }
}

class _PayPalSection extends StatelessWidget {
  final VoidCallback onPayPalTap;

  const _PayPalSection({required this.onPayPalTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPayPalTap,
        icon: const Icon(Icons.open_in_browser),
        label: const Text('Pay with PayPal'),
      ),
    );
  }
}

class _PayAppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _PayAppButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap ?? () {},
      child: FittedBox(child: Text(label)),
    );
  }
}

class _BankChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _BankChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
