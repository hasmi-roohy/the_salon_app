import 'package:flutter/material.dart';

import '../../domain/premium_models.dart';
import 'premium_payment_page.dart';

class PremiumPlansPage extends StatefulWidget {
  final PremiumFeature initialFeature;
  final bool allowLocalDevelopmentSimulation;

  const PremiumPlansPage({
    super.key,
    required this.initialFeature,
    this.allowLocalDevelopmentSimulation = false,
  });

  @override
  State<PremiumPlansPage> createState() => _PremiumPlansPageState();
}

class _PremiumPlansPageState extends State<PremiumPlansPage> {
  late final Set<PremiumFeature> _selectedFeatures;

  int get _selectedTotal => _selectedFeatures.fold(
    0,
    (total, feature) => total + feature.monthlyPrice,
  );

  @override
  void initState() {
    super.initState();
    _selectedFeatures = {widget.initialFeature};
  }

  void _toggleFeature(PremiumFeature feature, bool selected) {
    setState(() {
      if (selected) {
        _selectedFeatures.add(feature);
      } else if (_selectedFeatures.length > 1) {
        _selectedFeatures.remove(feature);
      }
    });
  }

  Future<void> _openPayment() async {
    final unlocked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PremiumPaymentPage(
          selectedFeatures: _selectedFeatures,
          totalAmount: _selectedTotal,
          allowLocalDevelopmentSimulation:
              widget.allowLocalDevelopmentSimulation,
        ),
      ),
    );
    if (unlocked == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salon Premium')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(
            Icons.workspace_premium,
            size: 58,
            color: Color(0xffb97816),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock your premium studio',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'Select only the premium features you want. The bill updates '
            'automatically.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'Premium features',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(width: 6),
              const Tooltip(
                triggerMode: TooltipTriggerMode.tap,
                showDuration: Duration(seconds: 6),
                preferBelow: true,
                message:
                    'AI Hair Studio creates realistic hairstyle and color previews.\n'
                    'AI Beard Studio previews beard, moustache, and grooming styles.\n'
                    'AI Nail Studio previews premium nail shapes, colors, and designs.\n'
                    'AI Mehndi Studio renders bridal, Arabic, and mandala designs.',
                child: Padding(
                  key: Key('premium-features-info'),
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.info_outline, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _PremiumFeatureSelector(
            selectedFeatures: _selectedFeatures,
            onChanged: _toggleFeature,
          ),
          const SizedBox(height: 12),
          _BillSummaryCard(
            selectedFeatures: _selectedFeatures,
            totalAmount: _selectedTotal,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _selectedFeatures.isEmpty ? null : _openPayment,
            icon: const Icon(Icons.shopping_cart_checkout),
            label: Text('Checkout - ${formatRupees(_selectedTotal)}'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Subscriptions renew until cancelled. Production pricing and '
            'billing terms must come from the app stores/payment provider.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PremiumFeatureSelector extends StatelessWidget {
  final Set<PremiumFeature> selectedFeatures;
  final void Function(PremiumFeature feature, bool selected) onChanged;

  const _PremiumFeatureSelector({
    required this.selectedFeatures,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (final feature in PremiumFeature.values) ...[
              _PremiumFeatureCheckbox(
                feature: feature,
                selected: selectedFeatures.contains(feature),
                onChanged: (selected) => onChanged(feature, selected),
              ),
              if (feature != PremiumFeature.values.last)
                const Divider(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _PremiumFeatureCheckbox extends StatelessWidget {
  final PremiumFeature feature;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _PremiumFeatureCheckbox({
    required this.feature,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: selected,
      onChanged: (value) => onChanged(value ?? false),
      secondary: CircleAvatar(
        backgroundColor: const Color(0xffe8efff),
        child: Icon(feature.icon, color: const Color(0xff245ca8)),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              feature.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            formatRupees(feature.monthlyPrice),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
      subtitle: Text(feature.description),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _BillSummaryCard extends StatelessWidget {
  final Set<PremiumFeature> selectedFeatures;
  final int totalAmount;

  const _BillSummaryCard({
    required this.selectedFeatures,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xffeef5ff),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bill summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final feature in selectedFeatures)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
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
            const SizedBox(height: 4),
            Text(
              'Demo pricing for UI review. Production pricing should come '
              'from the billing provider.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
