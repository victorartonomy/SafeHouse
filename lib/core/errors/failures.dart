import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

final class FilePickerFailure extends Failure {
  const FilePickerFailure([super.message = 'Failed to pick a file.']);
}

final class EncryptionFailure extends Failure {
  const EncryptionFailure([super.message = 'Encryption/decryption failed.']);
}

final class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Failed to read or write storage.']);
}

final class InvalidKeyFailure extends Failure {
  const InvalidKeyFailure([super.message = 'The provided key is invalid.']);
}

final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}
