part of 'history_cubit.dart';

/// Sealed state hierarchy for [HistoryCubit].
sealed class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

/// Idle, never loaded.
final class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

/// Fetching from Hive.
final class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

/// Records loaded successfully.
final class HistoryLoaded extends HistoryState {
  final List<EncryptedFile> records;

  const HistoryLoaded({required this.records});

  @override
  List<Object?> get props => [records];
}

/// An error occurred while reading or mutating the history.
final class HistoryError extends HistoryState {
  final String message;

  const HistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}
