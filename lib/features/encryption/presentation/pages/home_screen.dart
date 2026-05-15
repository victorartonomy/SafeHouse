import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_state.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../settings/presentation/cubits/settings_cubit.dart';
import '../../../settings/presentation/cubits/settings_state.dart';
import '../../../settings/presentation/pages/settings_screen.dart';

import '../../../cloud/presentation/pages/cloud_backup_screen.dart';

import '../../../calculator/presentation/pages/calculator_screen.dart';
import '../../../categories/presentation/pages/categories_screen.dart';
import 'decrypt_screen.dart';
import 'encrypt_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _showAboutDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('About SafeHouse'),
        content: const Text(
          'SafeHouse is a local AES-256 file encryption app. It lets you '
          'encrypt files, decrypt them back on-device, and keep a secure '
          'history of saved keys and file records without sending data off '
          'your device.\n\n'
          'Author: AINEL MARZIA BELGAUMKAR N\n'
          'email: ainalbelgaumkar@gmail.com\n'
          'registration number: P02ME24S126003\n'
          'guide: Manjula\n'
          'purpose: Final Year Project\n'
          'college: JSS, Dharwad\n',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.of(
            context,
          ).pushAndRemoveUntil(LoginScreen.route(), (route) => false);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // ── Hero header ────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SafeHouse',
                            style: theme.textTheme.headlineMedium,
                          ),
                          Text(
                            'AES-256 File Encryption',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        return IconButton(
                          onPressed: () => context.read<AuthCubit>().signOut(),
                          icon: const Icon(Icons.logout_rounded),
                          tooltip: 'Logout',
                          color: const Color(0xFFFF4D4D).withValues(alpha: 0.8),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                Text(
                  'ACTIONS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Navigation cards ───────────────────────────────────────
                _NavCard(
                  icon: Icons.lock_outline,
                  title: 'Encrypt File',
                  subtitle: 'Secure any file with AES-256',
                  accentColor: theme.colorScheme.primary,
                  onTap: () => Navigator.push(context, EncryptScreen.route()),
                ),
                const SizedBox(height: 10),
                _NavCard(
                  icon: Icons.lock_open_outlined,
                  title: 'Decrypt File',
                  subtitle: 'Recover an encrypted file',
                  accentColor: const Color(0xFF4FC3F7),
                  onTap: () => Navigator.push(context, DecryptScreen.route()),
                ),
                const SizedBox(height: 10),
                _NavCard(
                  icon: Icons.history_outlined,
                  title: 'History',
                  subtitle: 'View saved keys & encrypted files',
                  accentColor: const Color(0xFFFFB74D),
                  onTap: () => Navigator.push(context, HistoryScreen.route()),
                ),
                const SizedBox(height: 10),
                _NavCard(
                  icon: Icons.folder_outlined,
                  title: 'Categories',
                  subtitle: 'Manage password-protected categories',
                  accentColor: const Color(0xFF81C784),
                  onTap: () =>
                      Navigator.push(context, CategoriesScreen.route()),
                ),
                const SizedBox(height: 10),

                // Cloud Backup Card - Listens to SettingsCubit
                BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, state) {
                    bool isEnabled = false;
                    if (state is SettingsLoaded) {
                      isEnabled = state.isCloudStorageEnabled;
                    } else if (state is SettingsActionSuccess) {
                      isEnabled = state.isCloudStorageEnabled;
                    } else if (state is SettingsError) {
                      isEnabled = state.isCloudStorageEnabled ?? false;
                    }

                    return _NavCard(
                      icon: Icons.cloud_upload_outlined,
                      title: 'Cloud Backup',
                      subtitle: isEnabled
                          ? 'Sync your encrypted files to cloud'
                          : 'Cloud storage is disabled in settings',
                      accentColor: isEnabled
                          ? const Color(0xFFB39DDB)
                          : Colors.grey,
                      onTap: () {
                        if (!isEnabled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enable Cloud Storage in Settings first.',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.push(context, CloudBackupScreen.route());
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Settings Card
                _NavCard(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Theme, Cloud, and Account',
                  accentColor: const Color(0xFFF06292),
                  onTap: () => Navigator.push(context, SettingsScreen.route()),
                ),
                const SizedBox(height: 10),

                // Return to Calculator (locks app — re-entry needs 158+-=)
                _NavCard(
                  icon: Icons.calculate_outlined,
                  title: 'Return to Calculator',
                  subtitle: 'Lock the app and show the calculator',
                  accentColor: const Color(0xFF4285F4),
                  onTap: () => Navigator.of(context).pushAndRemoveUntil(
                    CalculatorScreen.route(),
                    (_) => false,
                  ),
                ),

                const Spacer(),

                // ── Footer ─────────────────────────────────────────────────
                Center(
                  child: Text(
                    'End-to-end encrypted · Keys never leave your device',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: InkWell(
                    onTap: () => _showAboutDialog(context),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Text(
                        'About',
                        style: theme.textTheme.labelSmall?.copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: theme.colorScheme.primary,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: accentColor.withValues(alpha: 0.06),
        highlightColor: accentColor.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              // Colored icon badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
