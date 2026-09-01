import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/user_model.dart';
import 'widgets/custom_password_field.dart';
import 'widgets/custom_text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController(text: 'ravi@cityzoo.com');
  final _passwordController = TextEditingController(text: 'Password123!');
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, String>> _demoProfiles = [
    {
      'name': 'Ravi Kumar',
      'email': 'ravi@cityzoo.com',
      'role': 'Zone Incharge / Staff',
      'scope': 'North Wing Tree (Cascading)',
    },
    {
      'name': 'Amit Shah',
      'email': 'amit@example.com',
      'role': 'Technician',
      'scope': 'Assigned Issue Queue',
    },
    {
      'name': 'Priya Singh',
      'email': 'priya@cityzoo.com',
      'role': 'Client Admin',
      'scope': 'City Zoo (All Zones)',
    },
    {
      'name': 'Sarah Connor',
      'email': 'staff@zoo.com',
      'role': 'Zone Staff',
      'scope': 'Safari Zone',
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
      setState(() => _errorMessage = 'Please enter both email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Attempt Real Backend Login via Riverpod AuthProvider
      await ref
          .read(authStateProvider.notifier)
          .login(email: targetEmail, password: targetPassword);
      AppLogger.i('🎉 [LoginPage] Login successful for $targetEmail');
    } catch (e, st) {
      AppLogger.e('💥 [LoginPage] Login failed: $e', e, st);

      // 2. If backend is offline or network error during early dev, offer friendly fallback
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception:', '').trim();

        // If backend connection refused, let them use offline dev mode seamlessly
        if (errorMsg.contains('Connection refused') ||
            errorMsg.contains('SocketException') ||
            errorMsg.contains('connection timeout')) {
          _promptOfflineDevLogin(targetEmail);
        } else {
          setState(() {
            _errorMessage = errorMsg;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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

    AppSnackbar.warning('Could not reach server. Started offline dev session.');
  }

  @override
  Widget build(BuildContext context) {
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
                      Icons.shield_outlined,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Title & Subtitle
                const Text(
                  "Equipment Hub",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Maintenance & Device Management System",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 20),

                // Error Message if any
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 18,
                          color: AppColors.errorText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.errorText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    onPressed: _isLoading ? null : () => _handleLogin(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
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
                ..._demoProfiles.map((profile) {
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
                      onTap: _isLoading
                          ? null
                          : () {
                              _emailController.text = profile['email']!;
                              _passwordController.text = 'Password123!';
                              _handleLogin(profile['email'], 'Password123!');
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
                                    '${profile['email']!} • ${profile['scope']!}',
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
