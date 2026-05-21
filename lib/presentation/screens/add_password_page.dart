import 'package:flutter/material.dart';
import 'package:passwordmanager/presentation/screens/controllers/add_password_page_controller.dart';

class AddPasswordPage extends StatefulWidget {
  const AddPasswordPage({super.key});

  @override
  State<AddPasswordPage> createState() => _AddPasswordPageState();
}

class _AddPasswordPageState extends State<AddPasswordPage>
    with TickerProviderStateMixin {
  late AddPasswordController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AddPasswordController(vsync: this);

    // Listen for save events
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    final event = _controller.lastEvent;
    if (event != null) {
      if (event.event == AddPasswordEvent.saveSuccess) {
        _controller.consumeEvent();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password saved successfully'),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context);
        }
      } else if (event.event == AddPasswordEvent.saveError) {
        _controller.consumeEvent();
        if (mounted && event.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(event.errorMessage!),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _showCategoryDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Category',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...AddPasswordController.availableCategories.map((category) {
                return ListTile(
                  leading: Icon(
                    _getCategoryIcon(category),
                    color: Colors.blue.shade700,
                  ),
                  title: Text(
                    category,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: _controller.selectedCategory == category
                      ? Icon(Icons.check_circle, color: Colors.green.shade400)
                      : null,
                  onTap: () {
                    _controller.setCategory(category);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Social':
        return Icons.people;
      case 'Email':
        return Icons.email;
      case 'Banking':
        return Icons.account_balance;
      case 'Shopping':
        return Icons.shopping_cart;
      case 'Entertainment':
        return Icons.movie;
      case 'Work':
        return Icons.work;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a001c),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          "Add Password",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FadeTransition(
                  opacity: _controller.fadeIn,
                  child: SlideTransition(
                    position: _controller.slideUp,
                    child: Form(
                      key: _controller.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderCard(),
                          const SizedBox(height: 24),
                          const Text(
                            'Credentials',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildAppNameField(),
                          const SizedBox(height: 16),
                          _buildUsernameField(),
                          const SizedBox(height: 16),
                          _buildPasswordField(),
                          const SizedBox(height: 24),
                          const Text(
                            'Additional Options',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildCategorySelector(),
                          const SizedBox(height: 16),
                          _buildNotesField(),
                          const SizedBox(height: 24),
                          _buildActionButtons(),
                          const SizedBox(height: 16),
                          _buildSecurityNote(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.purple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Colors.white70,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add New Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Securely store your login credentials',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'End-to-end encrypted',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppNameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _controller.appNameController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: "App / Website",
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.web,
            color: Colors.blue.shade700,
            size: 22,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          errorStyle: const TextStyle(color: Colors.redAccent),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: _controller.validateAppName,
      ),
    );
  }

  Widget _buildUsernameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _controller.usernameController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: "Username / Email",
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.person,
            color: Colors.blue.shade700,
            size: 22,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          errorStyle: const TextStyle(color: Colors.redAccent),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: _controller.validateUsername,
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _controller.passwordController,
            obscureText: !_controller.isPasswordVisible,
            style: const TextStyle(color: Colors.white),
            onChanged: (value) => _controller.updatePasswordStrength(value),
            decoration: InputDecoration(
              labelText: "Password",
              labelStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.lock,
                color: Colors.blue.shade700,
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _controller.isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 22,
                ),
                onPressed: _controller.togglePasswordVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              errorStyle: const TextStyle(color: Colors.redAccent),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: _controller.validatePassword,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _controller.passwordStrengthPercentage,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _controller.passwordStrength.color,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _controller.passwordStrength.color
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _controller.passwordStrength.color
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStrengthIcon(),
                            color: _controller.passwordStrength.color,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _controller.passwordStrength.label,
                            style: TextStyle(
                              color: _controller.passwordStrength.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildRequirementChip('8+ chars',
                        _controller.passwordRequirements['length']!),
                    _buildRequirementChip('Uppercase',
                        _controller.passwordRequirements['uppercase']!),
                    _buildRequirementChip('Lowercase',
                        _controller.passwordRequirements['lowercase']!),
                    _buildRequirementChip('Numbers',
                        _controller.passwordRequirements['numbers']!),
                    _buildRequirementChip('Special',
                        _controller.passwordRequirements['special']!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStrengthIcon() {
    switch (_controller.passwordStrength) {
      case PasswordStrength.weak:
        return Icons.error_outline;
      case PasswordStrength.fair:
        return Icons.info_outline;
      case PasswordStrength.good:
        return Icons.check_circle_outline;
      case PasswordStrength.strong:
        return Icons.shield;
    }
  }

  Widget _buildRequirementChip(String label, bool met) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: met
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: met
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: met
                ? Colors.green.shade400
                : Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: met
                  ? Colors.green.shade400
                  : Colors.white.withValues(alpha: 0.6),
              fontWeight: met ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.category,
          color: Colors.blue.shade700,
        ),
        title: const Text(
          'Category',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          _controller.selectedCategory ?? 'Select a category',
          style: TextStyle(
            color: _controller.selectedCategory != null
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.7),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white.withValues(alpha: 0.5),
          size: 16,
        ),
        onTap: _showCategoryDialog,
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _controller.notesController,
        maxLines: 3,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: "Notes (Optional)",
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(bottom: 50),
            child: Icon(
              Icons.note,
              color: Colors.blue,
              size: 22,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.blue.shade700),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _controller.isLoading ? null : _controller.savePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 5,
              shadowColor: Colors.blue.withValues(alpha: 0.3),
            ),
            child: _controller.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityNote() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: .2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.security,
              color: Colors.blue.shade700,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Your data is encrypted and secure',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
