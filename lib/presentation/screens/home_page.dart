import 'package:flutter/material.dart';
import 'package:passwordmanager/presentation/widgets/password_card_widget.dart';
import 'add_password_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        title: Text(
          "Password Manager",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 24,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show more options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Security Status Card - Using theme colors
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        colorScheme.primary.withOpacity(0.8),
                        colorScheme.secondary.withOpacity(0.8),
                      ]
                    : [Colors.blue.shade700, Colors.purple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? colorScheme.primary : Colors.blue)
                      .withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Status',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your vault is secure',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '92%',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatusIndicator(
                      context,
                      icon: Icons.check_circle,
                      label: 'Strong',
                      value: '12',
                      color: Colors.green.shade300,
                    ),
                    const SizedBox(width: 20),
                    _buildStatusIndicator(
                      context,
                      icon: Icons.warning,
                      label: 'Weak',
                      value: '3',
                      color: Colors.orange.shade300,
                    ),
                    const SizedBox(width: 20),
                    _buildStatusIndicator(
                      context,
                      icon: Icons.error,
                      label: 'Reused',
                      value: '5',
                      color: Colors.red.shade300,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Passwords',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    // View all
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),

          // Password List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PasswordCard(
                  title: "Facebook",
                  username: "john.doe@email.com",
                  category: "Social Media",
                  strength: 85,
                  lastUsed: "2 days ago",
                  iconData: Icons.facebook,
                  iconColor: Colors.blue.shade700,
                  onTap: () {
                    // Show password details
                  },
                  onCopy: () {
                    // Copy username
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Username copied to clipboard',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: colorScheme.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                PasswordCard(
                  title: "Google",
                  username: "john.doe@gmail.com",
                  category: "Email",
                  strength: 95,
                  lastUsed: "5 hours ago",
                  iconData: Icons.email,
                  iconColor: Colors.red.shade700,
                  onTap: () {
                    // Show password details
                  },
                  onCopy: () {
                    // Copy username
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Username copied to clipboard',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: colorScheme.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                PasswordCard(
                  title: "Amazon",
                  username: "john.shopper",
                  category: "Shopping",
                  strength: 70,
                  lastUsed: "1 week ago",
                  iconData: Icons.shopping_cart,
                  iconColor: Colors.amber.shade700,
                  onTap: () {
                    // Show password details
                  },
                  onCopy: () {
                    // Copy username
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Username copied to clipboard',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: colorScheme.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                PasswordCard(
                  title: "GitHub",
                  username: "john.dev",
                  category: "Development",
                  strength: 100,
                  lastUsed: "Yesterday",
                  iconData: Icons.code,
                  iconColor: Colors.grey.shade800,
                  onTap: () {
                    // Show password details
                  },
                  onCopy: () {
                    // Copy username
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Username copied to clipboard',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: colorScheme.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                PasswordCard(
                  title: "Netflix",
                  username: "john.watcher",
                  category: "Entertainment",
                  strength: 65,
                  lastUsed: "3 days ago",
                  iconData: Icons.movie,
                  iconColor: Colors.red.shade900,
                  onTap: () {
                    // Show password details
                  },
                  onCopy: () {
                    // Copy username
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Username copied to clipboard',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: colorScheme.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPasswordPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Password'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildStatusIndicator(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
