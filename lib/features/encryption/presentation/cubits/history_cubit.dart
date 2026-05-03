import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/encrypted_file.dart';
import '../../domain/repositories/encryption_repository.dart';

part 'history_state.dart';

/// Cubit owning the encrypted-file history list.
///
/// UI usage:
///
/// ```dart
/// context.read<HistoryCubit>().loadHistory();
/// ```
class HistoryCubit extends Cubit<HistoryState> {
  final EncryptionRepository _repository;

  HistoryCubit({required EncryptionRepository repository})
      : _repository = repository,
        super(const HistoryInitial());

  /// Loads all history records from Hive, sorted newest-first.
  Future<void> loadHistory() async {
    emit(const HistoryLoading());
    try {
      final records = await _repository.getHistory();
      emit(HistoryLoaded(records: records));
    } on Failure catch (f) {
      emit(HistoryError(message: f.message));
    } catch (e) {
      emit(HistoryError(message: 'Failed to load history: $e'));
    }
  }

  /// Deletes one record (and its on-disk file) by [id], then re-fetches.
  Future<void> deleteEntry(String id) async {
    try {
      await _repository.deleteHistoryEntry(id);
      await _refresh();
    } on Failure catch (f) {
      emit(HistoryError(message: f.message));
    } catch (e) {
      emit(HistoryError(message: 'Failed to delete entry: $e'));
    }
  }

  /// Deletes all records and emits an empty [HistoryLoaded].
  Future<void> clearHistory() async {
    try {
      await _repository.clearHistory();
      emit(const HistoryLoaded(records: []));
    } on Failure catch (f) {
      emit(HistoryError(message: f.message));
    } catch (e) {
      emit(HistoryError(message: 'Failed to clear history: $e'));
    }
  }

  /// Re-fetches records without emitting [HistoryLoading], preventing the
  /// list from flashing a spinner after a single-item mutation.
  Future<void> _refresh() async {
    try {
      final records = await _repository.getHistory();
      emit(HistoryLoaded(records: records));
    } on Failure catch (f) {
      emit(HistoryError(message: f.message));
    } catch (e) {
      emit(HistoryError(message: 'Failed to refresh history: $e'));
    }
  }
}
