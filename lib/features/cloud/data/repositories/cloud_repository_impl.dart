import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/cloud_transfer.dart';
import '../../domain/repositories/cloud_repository.dart';
import '../datasources/cloud_remote_datasource.dart';

class CloudRepositoryImpl implements CloudRepository {
  final CloudRemoteDataSource remoteDataSource;

  CloudRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<CloudTransferEvent> uploadFile({
    required String filePath,
    required String remoteFileName,
    required CloudTransferHandle handle,
  }) {
    return remoteDataSource.uploadFile(
      filePath: filePath,
      remoteFileName: remoteFileName,
      handle: handle,
    );
  }

  @override
  Stream<CloudTransferEvent> downloadFile({
    required String remoteFileName,
    required CloudTransferHandle handle,
  }) {
    return remoteDataSource.downloadFile(
      remoteFileName: remoteFileName,
      handle: handle,
    );
  }

  @override
  Future<Either<Failure, List<CloudFile>>> getCloudFiles() async {
    try {
      final files = await remoteDataSource.getCloudFiles();
      return Right(files);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCloudFile(String fileName) async {
    try {
      await remoteDataSource.deleteCloudFile(fileName);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAllCloudFiles() async {
    try {
      await remoteDataSource.deleteAllCloudFiles();
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isCloudStorageEnabled() async {
    try {
      final enabled = await remoteDataSource.isCloudStorageEnabled();
      return Right(enabled);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setCloudStorageEnabled(bool enabled) async {
    try {
      await remoteDataSource.setCloudStorageEnabled(enabled);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}
