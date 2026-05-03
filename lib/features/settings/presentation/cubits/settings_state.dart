import 'package:equatable/equatable.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

final class SettingsInitial extends SettingsState {}

final class SettingsLoading extends SettingsState {}

final class SettingsLoaded extends SettingsState {
  final bool isCloudStorageEnabled;

  const SettingsLoaded({required this.isCloudStorageEnabled});

  @override
  List<Object?> get props => [isCloudStorageEnabled];
}

final class SettingsActionSuccess extends SettingsState {
  final String message;
  final bool isCloudStorageEnabled;

  const SettingsActionSuccess({
    required this.message,
    required this.isCloudStorageEnabled,
  });

  @override
  List<Object?> get props => [message, isCloudStorageEnabled];
}

final class SettingsError extends SettingsState {
  final String message;
  final bool? isCloudStorageEnabled; // Optional fallback state

  const SettingsError({required this.message, this.isCloudStorageEnabled});

  @override
  List<Object?> get props => [message, isCloudStorageEnabled];
}
