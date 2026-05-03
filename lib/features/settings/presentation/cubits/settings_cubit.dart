import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../cloud/domain/repositories/cloud_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final CloudRepository _cloudRepository;
  final AuthCubit _authCubit;
  final ThemeNotifier _themeNotifier;

  SettingsCubit({
    required CloudRepository cloudRepository,
    required AuthCubit authCubit,
    required ThemeNotifier themeNotifier,
  }) : _cloudRepository = cloudRepository,
       _authCubit = authCubit,
       _themeNotifier = themeNotifier,
       super(SettingsInitial()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    emit(SettingsLoading());
    final result = await _cloudRepository.isCloudStorageEnabled();
    result.fold(
      (failure) => emit(
        SettingsError(message: failure.message, isCloudStorageEnabled: false),
      ),
      (isEnabled) => emit(SettingsLoaded(isCloudStorageEnabled: isEnabled)),
    );
  }

  Future<void> toggleCloudStorage(bool enable) async {
    emit(SettingsLoading());
    final result = await _cloudRepository.setCloudStorageEnabled(enable);
    result.fold(
      (failure) => emit(
        SettingsError(message: failure.message, isCloudStorageEnabled: !enable),
      ),
      (_) => emit(SettingsLoaded(isCloudStorageEnabled: enable)),
    );
  }

  Future<void> deleteAllCloudFiles() async {
    final currentState = state;
    final isEnabled = currentState is SettingsLoaded
        ? currentState.isCloudStorageEnabled
        : false;

    emit(SettingsLoading());
    final result = await _cloudRepository.deleteAllCloudFiles();
    result.fold(
      (failure) => emit(
        SettingsError(
          message: failure.message,
          isCloudStorageEnabled: isEnabled,
        ),
      ),
      (_) => emit(
        SettingsActionSuccess(
          message: 'All cloud files deleted successfully.',
          isCloudStorageEnabled: isEnabled,
        ),
      ),
    );
  }

  Future<void> deleteAccount() async {
    // Calling deleteAccount on AuthCubit handles the actual deletion and state emission
    await _authCubit.deleteAccount();
  }

  void setThemeMode(AppThemeMode mode) {
    _themeNotifier.setThemeMode(mode);
  }

  void setAccentColor(Color color) {
    _themeNotifier.setAccentColor(color);
  }
}
