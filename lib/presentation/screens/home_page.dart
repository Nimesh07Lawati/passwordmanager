import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:passwordmanager/presentation/widgets/password_card_widget.dart';
import 'package:passwordmanager/core/theme/app_theme.dart';
import 'add_password_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _pulseController;
  late Animation<double> _cardAnimation;
  late Animation<double> _pulseAnimation;

  int _selectedCategory = 0;
  final List<String> _categories = [
    'All',
    'Social',
    'Email',
    'Work',
    'Shopping'
  ];

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _cardController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: t.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(t),
      body: Stack(
        children: [
          // Background ambient glow
          Positioned(
            top: -80,
            right: -60,
            child: _AmbientGlow(
              color: const Color(0xFF1565C0).withOpacity(isDark ? 0.25 : 0.10),
              size: 280,
            ),
          ),
          Positioned(
            top: 200,
            left: -80,
            child: _AmbientGlow(
              color: const Color(0xFF6A1B9A).withOpacity(isDark ? 0.18 : 0.07),
              size: 220,
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Hero Security Card ──────────────────────────────────────
                FadeTransition(
                  opacity: _cardAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(_cardAnimation),
                    child: _SecurityCard(
                      pulse: _pulseAnimation,
                      theme: t,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Category Chips ──────────────────────────────────────────
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final selected = _selectedCategory == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF1565C0)
                                : t.surfaceHigh,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF1565C0)
                                  : t.borderColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _categories[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? Colors.white : t.textSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // ── Section Header ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Passwords',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Password List ───────────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      ..._buildPasswordItems(context, t),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButton: _StyledFAB(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPasswordPage()),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppThemeExtension t) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good morning,',
            style: TextStyle(
              fontSize: 13,
              color: t.textHint,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
          ),
          Text(
            'John 👋',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: t.textPrimary,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search_rounded, color: t.textSecondary, size: 22),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: t.cardGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'JD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPasswordItems(BuildContext context, AppThemeExtension t) {
    final items = [
      _PasswordItem(
        title: 'Facebook',
        username: 'john.doe@email.com',
        category: 'Social Media',
        strength: 85,
        lastUsed: '2 days ago',
        iconData: Icons.facebook_rounded,
        iconColor: const Color(0xFF1877F2),
        delay: 0,
      ),
      _PasswordItem(
        title: 'Google',
        username: 'john.doe@gmail.com',
        category: 'Email',
        strength: 95,
        lastUsed: '5 hours ago',
        iconData: Icons.email_rounded,
        iconColor: const Color(0xFFEA4335),
        delay: 60,
      ),
      _PasswordItem(
        title: 'Amazon',
        username: 'john.shopper',
        category: 'Shopping',
        strength: 70,
        lastUsed: '1 week ago',
        iconData: Icons.shopping_bag_rounded,
        iconColor: const Color(0xFFFF9900),
        delay: 120,
      ),
      _PasswordItem(
        title: 'GitHub',
        username: 'john.dev',
        category: 'Development',
        strength: 100,
        lastUsed: 'Yesterday',
        iconData: Icons.code_rounded,
        iconColor: const Color(0xFF6E40C9),
        delay: 180,
      ),
      _PasswordItem(
        title: 'Netflix',
        username: 'john.watcher',
        category: 'Entertainment',
        strength: 65,
        lastUsed: '3 days ago',
        iconData: Icons.movie_rounded,
        iconColor: const Color(0xFFE50914),
        delay: 240,
      ),
    ];

    return items
        .map((item) => _AnimatedPasswordTile(
            item: item, theme: t, parentAnimation: _cardAnimation))
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Security Hero Card
// ─────────────────────────────────────────────────────────────────────────────
class _SecurityCard extends StatelessWidget {
  final Animation<double> pulse;
  final AppThemeExtension theme;

  const _SecurityCard({required this.pulse, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.45),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              right: 60,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Security Score',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Your vault is secure',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                      ScaleTransition(
                        scale: pulse,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '92',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  height: 1,
                                ),
                              ),
                              Text(
                                '%',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.92,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _buildStat(Icons.check_circle_outline_rounded, '12',
                          'Strong', const Color(0xFF66BB6A)),
                      _buildDivider(),
                      _buildStat(Icons.warning_amber_rounded, '3', 'Weak',
                          const Color(0xFFFFB74D)),
                      _buildDivider(),
                      _buildStat(Icons.content_copy_rounded, '5', 'Reused',
                          const Color(0xFFEF9A9A)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.2),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Password Tile
// ─────────────────────────────────────────────────────────────────────────────
class _PasswordItem {
  final String title;
  final String username;
  final String category;
  final int strength;
  final String lastUsed;
  final IconData iconData;
  final Color iconColor;
  final int delay;

  const _PasswordItem({
    required this.title,
    required this.username,
    required this.category,
    required this.strength,
    required this.lastUsed,
    required this.iconData,
    required this.iconColor,
    required this.delay,
  });
}

class _AnimatedPasswordTile extends StatelessWidget {
  final _PasswordItem item;
  final AppThemeExtension theme;
  final Animation<double> parentAnimation;

  const _AnimatedPasswordTile({
    required this.item,
    required this.theme,
    required this.parentAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final Color strengthColor = item.strength >= 90
        ? const Color(0xFF66BB6A)
        : item.strength >= 70
            ? const Color(0xFFFFB74D)
            : const Color(0xFFEF5350);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            color: t.surfaceHigh,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.borderColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: item.iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.iconData, color: item.iconColor, size: 22),
                ),
                const SizedBox(width: 14),

                // Title + username
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.username,
                        style: TextStyle(
                          fontSize: 12,
                          color: t.textHint,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Strength bar
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: item.strength / 100,
                                backgroundColor: t.borderColor,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    strengthColor),
                                minHeight: 3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${item.strength}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: strengthColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Actions column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.title} password copied'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.copy_rounded,
                          size: 15,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.lastUsed,
                      style: TextStyle(
                        fontSize: 10,
                        color: t.textDisabled,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Styled FAB
// ─────────────────────────────────────────────────────────────────────────────
class _StyledFAB extends StatelessWidget {
  final VoidCallback onTap;
  const _StyledFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Add Password',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ambient glow background helper
// ─────────────────────────────────────────────────────────────────────────────
class _AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;
  const _AmbientGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
