import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/auth_service.dart';

/// Production authentication screen supporting Google Sign-In and private user accounts
class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum _AuthMode { signIn, signUp }

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  _AuthMode _mode = _AuthMode.signIn;
  bool _isArabic = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _error;
  bool _obscurePassword = true;

  Future<void> _submitGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _error = null;
    });

    final result = await _authService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result.success) {
      widget.onAuthenticated();
    } else {
      setState(() => _error = result.error);
    }
  }

  Future<void> _submitEmailAuth() async {
    final loc = AppLocalizations(isArabic: _isArabic);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = _isArabic ? 'يرجى إدخال البريد الإلكتروني وكلمة المرور' : 'Please enter email and password');
      return;
    }

    if (password.length < 6) {
      setState(() => _error = loc.passwordTooShort);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = _mode == _AuthMode.signUp
        ? await _authService.signUp(email, password)
        : await _authService.signIn(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      widget.onAuthenticated();
    } else {
      setState(() => _error = result.error);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(isArabic: _isArabic);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          children: [
            // Top Bar with Language Toggle
            Positioned(
              top: 16,
              right: _isArabic ? null : 16,
              left: _isArabic ? 16 : null,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _isArabic = !_isArabic),
                icon: const Icon(Icons.language_rounded, size: 16),
                label: Text(
                  _isArabic ? 'English' : 'العربية',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Official Brand Logo
                          Image.asset(
                            'assets/wardhelm_logo.png',
                            width: 72,
                            height: 72,
                            errorBuilder: (_, _, _) => Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                color: AppColors.primary,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            loc.appTitle,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _mode == _AuthMode.signUp ? loc.registerSubtitle : loc.loginSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Direct Google Sign-In Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: (_isGoogleLoading || _isLoading) ? null : _submitGoogleSignIn,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: isDark
                                    ? Colors.white.withOpacity(0.04)
                                    : Colors.white,
                              ),
                              child: _isGoogleLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildGoogleBadge(),
                                        const SizedBox(width: 12),
                                        Text(
                                          loc.continueWithGoogle,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Divider with text
                          Row(
                            children: [
                              Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey.shade300)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  loc.orByEmail,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey.shade300)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Mode Switcher Tabs
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildModeTab(
                                    title: loc.loginBtn,
                                    mode: _AuthMode.signIn,
                                  ),
                                ),
                                Expanded(
                                  child: _buildModeTab(
                                    title: loc.registerTitle,
                                    mode: _AuthMode.signUp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Error Box
                          if (_error != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Email & Password Fields
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: loc.email,
                              hintText: 'name@example.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: loc.password,
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            onSubmitted: (_) => _submitEmailAuth(),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitEmailAuth,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(_mode == _AuthMode.signUp
                                      ? loc.createAccountBtn
                                      : loc.loginBtn),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleBadge() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildModeTab({required String title, required _AuthMode mode}) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = mode;
          _error = null;
        });
      },
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          );
        },
      ),
    );
  }
}
