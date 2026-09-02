import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/user_model.dart';
import 'widgets/custom_password_field.dart';
import 'widgets/custom_text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController(text: 'rajumistrri@gmail.com');
  final _passwordController = TextEditingController(text: 'Password123!');
  String? _localValidationError;

  final List<Map<String, String>> _quickLogins = const [
    {
      'name': 'Ravi Kumar',
      'role': 'Zone Incharge / Staff',
      'email': 'ravi@cityzoo.com',
      'pass': 'Password123!',
      'icon': 'shield',
    },
    {
      'name': 'Amit Shah',
      'role': 'Hardware Technician',
      'email': 'amit@example.com',
      'pass': 'Password123!',
      'icon': 'tech',
    },
    {
      'name': 'Pooja Nair',
      'role': 'Zone Incharge',
      'email': 'pooja@cityzoo.com',
      'pass': 'Password123!',
      'icon': 'shield',
    },
    {
      'name': 'System Admin',
      'role': 'Full Platform Scope',
      'email': 'admin@cityzoo.com',
      'pass': 'Password123!',
      'icon': 'admin',
    },
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin([String? email, String? password]) async {
    final targetEmail = email ?? _emailController.text.trim();
    final targetPassword = password ?? _passwordController.text.trim();

    AppLogger.i('👆 [LoginPage] Login triggered for: $targetEmail');

    if (targetEmail.isEmpty || targetPassword.isEmpty) {
      setState(
        () => _localValidationError = 'Please enter both email and password',
      );
      return;
    }

    setState(() => _localValidationError = null);
    ref.read(loginControllerProvider.notifier).clearError();

    final success = await ref
        .read(loginControllerProvider.notifier)
        .login(email: targetEmail, password: targetPassword);

    if (success) {
      AppLogger.i('🎉 [LoginPage] Login successful for $targetEmail');
    } else {
      final err = ref.read(loginControllerProvider).error;
      final errMsg = err?.toString() ?? '';
      if (errMsg.contains('Connection refused') ||
          errMsg.contains('SocketException') ||
          errMsg.contains('timeout') ||
          errMsg.contains('Cannot reach server')) {
        _promptOfflineDevLogin(targetEmail);
      }
    }
  }

  void _promptOfflineDevLogin(String email) {
    final isTech =
        email.toLowerCase().contains('amit') ||
        email.toLowerCase().contains('tech');
    final storage = ref.read(storageServiceProvider);

    final mockUser = UserModel(
      id: isTech ? 'usr-tech-amit' : 'usr-incharge-ravi',
      name: isTech ? 'Amit Shah (Technician)' : 'Ravi Kumar (Zone Incharge)',
      email: email,
      role: isTech ? UserRole.technician : UserRole.zoneIncharge,
      clientId: 'c2222222-2222-2222-2222-222222222222',
      assignedZoneId: 'a0000000-0000-0000-0000-000000000001',
      assignedZoneName: 'North Wing (Main)',
    );

    storage.saveTokens(
      accessToken: 'offline-dev-token',
      refreshToken: 'offline-refresh-token',
    );
    storage.saveUser(mockUser);

    // Update state to trigger navigation
    ref.invalidate(authStateProvider);
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.isLoading;

    String? errorMessage = _localValidationError;
    if (loginState.hasError) {
      var raw = loginState.error
          .toString()
          .replaceAll('Exception:', '')
          .replaceAll('Exception', '')
          .trim();
      errorMessage = raw.isNotEmpty ? raw : 'Invalid email or password';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Brand Icon
                Center(
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.hardware_outlined,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Title & Subtitle
                const Text(
                  AppConfig.appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  AppConfig.appTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 20),

                // Custom Error Banner
                if (errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFF87171),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.priority_high_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Authentication Error',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                errorMessage,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFB91C1C),
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() => _localValidationError = null);
                            ref
                                .read(loginControllerProvider.notifier)
                                .clearError();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Email Input
                CustomTextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  labelText: "Email Address",
                  hintText: "ravi@cityzoo.com",
                  prefixIcon: Icons.email_outlined,
                ),

                const SizedBox(height: 16),

                // Password Input
                CustomPasswordField(
                  controller: _passwordController,
                  labelText: "Password",
                  hintText: "••••••••",
                  prefixIcon: Icons.lock_outline,
                ),

                const SizedBox(height: 12),

                // Forgot Password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Login Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _handleLogin(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textWhite,
                              ),
                            ),
                          )
                        : const Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "Backend Seed Accounts (Tap to auto-login)",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),

                const SizedBox(height: 14),

                // Quick Demo Profiles List
                ..._quickLogins.map((profile) {
                  final isStaff =
                      profile['role']!.contains('Staff') ||
                      profile['role']!.contains('Incharge');
                  final isTech = profile['role']!.contains('Technician');

                  final roleBadgeColor = isStaff
                      ? AppColors.infoLight
                      : isTech
                      ? AppColors.warningLight
                      : AppColors.purpleLight;

                  final roleTextColor = isStaff
                      ? AppColors.infoText
                      : isTech
                      ? AppColors.warningText
                      : AppColors.purpleText;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: isLoading
                          ? null
                          : () {
                              _emailController.text = profile['email']!;
                              _passwordController.text = profile['pass']!;
                              _handleLogin(profile['email'], profile['pass']);
                            },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primaryBg,
                              child: Text(
                                profile['name']!.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile['name']!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    profile['email']!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: roleBadgeColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                profile['role']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: roleTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
