import 'package:equatable/equatable.dart';
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/cloud_transfer.dart';

enum CloudTransferKind { upload, download }

enum CloudTransferStatus { running, paused }

class CloudTransferProgress extends Equatable {
  final CloudTransferKind kind;
  final CloudTransferStatus status;
  final int bytesTransferred;
  final int totalBytes;
  final CloudTransferHandle handle;

  const CloudTransferProgress({
    required this.kind,
    required this.status,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.handle,
  });

  double get fraction => totalBytes == 0 ? 0 : bytesTransferred / totalBytes;

  CloudTransferProgress copyWith({
    CloudTransferStatus? status,
    int? bytesTransferred,
    int? totalBytes,
  }) {
    return CloudTransferProgress(
      kind: kind,
      status: status ?? this.status,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      handle: handle,
    );
  }

  @override
  List<Object?> get props => [kind, status, bytesTransferred, totalBytes];
}

sealed class CloudBackupState extends Equatable {
  const CloudBackupState();

  @override
  List<Object?> get props => [];
}

final class CloudBackupInitial extends CloudBackupState {}

final class CloudBackupLoading extends CloudBackupState {}

final class CloudBackupLoaded extends CloudBackupState {
  final List<CloudFile> files;
  final Map<String, CloudTransferProgress> transfers;

  const CloudBackupLoaded({
    required this.files,
    this.transfers = const {},
  });

  CloudBackupLoaded copyWith({
    List<CloudFile>? files,
    Map<String, CloudTransferProgress>? transfers,
  }) {
    return CloudBackupLoaded(
      files: files ?? this.files,
      transfers: transfers ?? this.transfers,
    );
  }

  @override
  List<Object?> get props => [files, transfers];
}

final class CloudBackupActionSuccess extends CloudBackupState {
  final String message;

  const CloudBackupActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

final class CloudBackupError extends CloudBackupState {
  final String message;

  const CloudBackupError({required this.message});

  @override
  List<Object?> get props => [message];
}
