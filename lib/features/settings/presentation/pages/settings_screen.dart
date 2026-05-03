import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../injection_container.dart';
import 'package:safe_house/features/auth/presentation/cubits/auth_state.dart';
import 'package:safe_house/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:safe_house/features/auth/presentation/pages/login_screen.dart';
import '../cubits/settings_cubit.dart';
import '../cubits/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static Route route() =>
      MaterialPageRoute(builder: (_) => const SettingsScreen());

  Future<void> _confirmDeleteFiles(
    BuildContext context,
    SettingsCubit cubit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Cloud Files?'),
        content: const Text(
          'This action will permanently delete all encrypted files '
          'stored in your Firebase Storage account. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Delete Files'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      cubit.deleteAllCloudFiles();
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    SettingsCubit cubit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete Account?',
          style: TextStyle(color: AppColors.red),
        ),
        content: const Text(
          'Are you sure you want to completely delete your account? '
          'This will remove all your data from the cloud and sign you out. '
          'Local files remain on your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      cubit.deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = sl<ThemeNotifier>();

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
              backgroundColor: AppColors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          leading: const BackButton(),
        ),
        body: BlocConsumer<SettingsCubit, SettingsState>(
          listener: (context, state) {
            if (state is SettingsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.red,
                ),
              );
            } else if (state is SettingsActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            final cubit = context.read<SettingsCubit>();
            final isLoading =
                state is SettingsLoading ||
                context.read<AuthCubit>().state is AuthLoading;

            bool isCloudEnabled = false;
            if (state is SettingsLoaded) {
              isCloudEnabled = state.isCloudStorageEnabled;
            } else if (state is SettingsActionSuccess) {
              isCloudEnabled = state.isCloudStorageEnabled;
            } else if (state is SettingsError) {
              isCloudEnabled = state.isCloudStorageEnabled ?? false;
            }

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // ── Theme Section ─────────────────────────────────────────────
                    Text(
                      'APPEARANCE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Theme Mode'),
                      subtitle: const Text(
                        'Switch between Light and Dark mode',
                      ),
                      trailing: SegmentedButton<AppThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: AppThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined),
                          ),
                          ButtonSegment(
                            value: AppThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                          ),
                        ],
                        selected: {themeNotifier.currentMode},
                        onSelectionChanged: (Set<AppThemeMode> newSelection) {
                          cubit.setThemeMode(newSelection.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Accent Color'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: AppColors.allAccents.map((color) {
                        final isSelected =
                            themeNotifier.currentAccentColor.toARGB32() ==
                            color.toARGB32();
                        return GestureDetector(
                          onTap: () => cubit.setAccentColor(color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: theme.colorScheme.onSurface,
                                      width: 3,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(),
                    ),

                    // ── Cloud Storage Section ───────────────────────────────────
                    Text(
                      'CLOUD STORAGE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Cloud Backup'),
                      subtitle: const Text(
                        'Upload encrypted files to Firebase Storage',
                      ),
                      value: isCloudEnabled,
                      activeTrackColor: theme.colorScheme.primary,
                      onChanged: isLoading
                          ? null
                          : (value) => cubit.toggleCloudStorage(value),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.delete_sweep_outlined,
                        color: AppColors.red,
                      ),
                      title: const Text(
                        'Delete All Cloud Files',
                        style: TextStyle(color: AppColors.red),
                      ),
                      subtitle: const Text(
                        'Permanently remove all files from cloud',
                      ),
                      onTap: isLoading
                          ? null
                          : () => _confirmDeleteFiles(context, cubit),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(),
                    ),

                    // ── Account Section ─────────────────────────────────────────
                    Text(
                      'ACCOUNT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.person_remove_alt_1_outlined,
                        color: AppColors.red,
                      ),
                      title: const Text(
                        'Delete Account',
                        style: TextStyle(color: AppColors.red),
                      ),
                      subtitle: const Text(
                        'Permanently delete your account and cloud data',
                      ),
                      onTap: isLoading
                          ? null
                          : () => _confirmDeleteAccount(context, cubit),
                    ),
                  ],
                ),
                if (isLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
