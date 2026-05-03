import 'package:equatable/equatable.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Events emitted on the stream returned by upload/download calls.
sealed class CloudTransferEvent extends Equatable {
  const CloudTransferEvent();
  @override
  List<Object?> get props => [];
}

final class CloudTransferRunning extends CloudTransferEvent {
  final int bytesTransferred;
  final int totalBytes;
  const CloudTransferRunning({
    required this.bytesTransferred,
    required this.totalBytes,
  });
  double get fraction => totalBytes == 0 ? 0 : bytesTransferred / totalBytes;
  @override
  List<Object?> get props => [bytesTransferred, totalBytes];
}

final class CloudTransferPaused extends CloudTransferEvent {
  final int bytesTransferred;
  final int totalBytes;
  const CloudTransferPaused({
    required this.bytesTransferred,
    required this.totalBytes,
  });
  double get fraction => totalBytes == 0 ? 0 : bytesTransferred / totalBytes;
  @override
  List<Object?> get props => [bytesTransferred, totalBytes];
}

final class CloudTransferSuccess extends CloudTransferEvent {
  /// For downloads, the local destination path. Null for uploads.
  final String? localPath;
  const CloudTransferSuccess({this.localPath});
  @override
  List<Object?> get props => [localPath];
}

final class CloudTransferCanceled extends CloudTransferEvent {
  const CloudTransferCanceled();
}

final class CloudTransferFailed extends CloudTransferEvent {
  final String message;
  const CloudTransferFailed(this.message);
  @override
  List<Object?> get props => [message];
}

/// Caller-owned handle the cubit uses to control a running transfer.
/// The datasource attaches the underlying Firebase [Task] once it starts.
class CloudTransferHandle {
  Task? _task;
  bool _canceled = false;

  void attach(Task task) {
    _task = task;
    if (_canceled) {
      // cancel() was called before the task attached — honor it now.
      task.cancel();
    }
  }

  Future<bool> pause() async {
    final t = _task;
    if (t == null) return false;
    return t.pause();
  }

  Future<bool> resume() async {
    final t = _task;
    if (t == null) return false;
    return t.resume();
  }

  Future<bool> cancel() async {
    _canceled = true;
    final t = _task;
    if (t == null) return true;
    return t.cancel();
  }
}
