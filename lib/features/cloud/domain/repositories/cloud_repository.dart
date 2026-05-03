import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cloud_file.dart';
import '../entities/cloud_transfer.dart';

abstract class CloudRepository {
  /// Upload a local file. Returns a stream of transfer events terminating in
  /// [CloudTransferSuccess], [CloudTransferCanceled], or [CloudTransferFailed].
  /// The provided [handle] is attached to the underlying task so the caller
  /// can pause/resume/cancel.
  Stream<CloudTransferEvent> uploadFile({
    required String filePath,
    required String remoteFileName,
    required CloudTransferHandle handle,
  });

  /// Download a cloud file by name to `SafeHouse/encrypted files/<remoteFileName>`.
  /// On success the event carries the resolved local path.
  Stream<CloudTransferEvent> downloadFile({
    required String remoteFileName,
    required CloudTransferHandle handle,
  });

  Future<Either<Failure, List<CloudFile>>> getCloudFiles();

  Future<Either<Failure, void>> deleteCloudFile(String fileName);

  Future<Either<Failure, void>> deleteAllCloudFiles();

  Future<Either<Failure, bool>> isCloudStorageEnabled();

  Future<Either<Failure, void>> setCloudStorageEnabled(bool enabled);
}
