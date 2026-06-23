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
  PremiumPlan _selectedPlan = premiumPlans.first;

  void _selectPlan(PremiumPlan plan) {
    setState(() => _selectedPlan = plan);
  }

  Future<void> _openPayment() async {
    final unlocked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PremiumPaymentPage(
          plan: _selectedPlan,
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
            'One subscription unlocks every premium try-on: hair, beard, and nails.',
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
                    'AI Nail Studio previews premium nail shapes, colors, and designs.',
                child: Padding(
                  key: Key('premium-features-info'),
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.info_outline, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _PremiumIncludesCard(),
          const SizedBox(height: 18),
          Text(
            'Choose a plan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...premiumPlans.map(
            (plan) => _PlanCard(
              plan: plan,
              selected: plan.id == _selectedPlan.id,
              onTap: () => _selectPlan(plan),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _openPayment,
            icon: const Icon(Icons.lock_open_outlined),
            label: const Text('Continue to payment'),
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

class _PlanCard extends StatelessWidget {
  final PremiumPlan plan;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? const Color(0xffe8efff) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? const Color(0xff245ca8) : Colors.black12,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (plan.recommended) ...[
                      const SizedBox(height: 4),
                      const _BestValueBadge(),
                    ],
                    Text(
                      'Unlocks hair, beard, and nail premium AI previews',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 92,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        plan.priceLabel,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      plan.billingLabel,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BestValueBadge extends StatelessWidget {
  const _BestValueBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.black12),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          'Best value',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _PremiumIncludesCard extends StatelessWidget {
  const _PremiumIncludesCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: const [
            _PremiumIncludeRow(
              icon: Icons.content_cut,
              title: 'AI Hair Studio',
              subtitle: 'Realistic hairstyle and color previews.',
            ),
            Divider(height: 18),
            _PremiumIncludeRow(
              icon: Icons.face_retouching_natural,
              title: 'AI Beard Studio',
              subtitle: 'Beard, moustache, and grooming previews.',
            ),
            Divider(height: 18),
            _PremiumIncludeRow(
              icon: Icons.back_hand_outlined,
              title: 'AI Nail Studio',
              subtitle: 'Premium nail shapes, colors, and designs.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumIncludeRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PremiumIncludeRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xffe8efff),
          child: Icon(icon, color: const Color(0xff245ca8)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(subtitle),
            ],
          ),
        ),
      ],
    );
  }
}
