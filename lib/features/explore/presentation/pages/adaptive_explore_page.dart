import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:the_salon_app/core/presentation/theme/app_theme.dart';

class AdaptiveExplorePage extends StatefulWidget {
  const AdaptiveExplorePage({super.key});

  @override
  State<AdaptiveExplorePage> createState() => _AdaptiveExplorePageState();
}

class _AdaptiveExplorePageState extends State<AdaptiveExplorePage> {
  final List<String> _categories = [
    'All',
    'Haircut',
    'Coloring',
    'Spa',
    'Massage',
    'Nails',
  ];

  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGreyScaffold,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 120.0,
            backgroundColor: AppTheme.lightGreyScaffold,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              title: Text(
                'Discover',
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(fontSize: 24),
              ),
              centerTitle: false,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: _buildSearchBar(),
            ),
          ),
          SliverToBoxAdapter(child: _buildCategoryPills()),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _buildSalonCard(index);
              }, childCount: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search salons, stylists, treatments...',
          hintStyle: TextStyle(
            color: AppTheme.textLight.withValues(alpha: 0.5),
          ),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textLight),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildCategoryPills() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildSalonCard(int index) {
    return _SalonCardWidget(index: index);
  }
}

class _SalonCardWidget extends StatefulWidget {
  final int index;
  const _SalonCardWidget({required this.index});

  @override
  State<_SalonCardWidget> createState() => _SalonCardWidgetState();
}

class _SalonCardWidgetState extends State<_SalonCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mock Image Area
                  Container(
                    height: 160,
                    decoration: const BoxDecoration(
                      color: AppTheme.secondaryDeepNavy,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.storefront,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Premium Salon ${widget.index + 1}',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontSize: 18),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: AppTheme.accentGold,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '4.${9 - (widget.index % 5)}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '123 Wellness Blvd • ${(widget.index + 1) * 2} km away',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (widget.index * 100).ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}
