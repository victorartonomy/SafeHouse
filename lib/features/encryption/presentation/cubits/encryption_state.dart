part of 'encryption_cubit.dart';

/// Sealed state hierarchy for [EncryptionCubit].
///
/// State machine:
///
///   Initial
///     └─▶ FileSelected  (user picked a file)
///           └─▶ Loading  (encryption / decryption in progress)
///                 ├─▶ EncryptionSuccess
///                 ├─▶ DecryptionSuccess
///                 └─▶ EncryptionError
///
/// KeyGenerated is an ephemeral state that fires when the user taps
/// "Generate Key". The UI uses a BlocListener to push the key into
/// the text field; the cubit immediately returns to its prior stable state.
sealed class EncryptionState extends Equatable {
  const EncryptionState();

  @override
  List<Object?> get props => [];
}

/// Nothing has happened yet on this screen.
final class EncryptionInitial extends EncryptionState {
  const EncryptionInitial();
}

/// User has picked a file; waiting for key input + action.
final class EncryptionFileSelected extends EncryptionState {
  final String filePath;
  final String fileName;

  const EncryptionFileSelected({
    required this.filePath,
    required this.fileName,
  });

  @override
  List<Object?> get props => [filePath, fileName];
}

/// An async operation (encrypt / decrypt) is in progress.
final class EncryptionLoading extends EncryptionState {
  final String message;

  const EncryptionLoading({this.message = 'Processing…'});

  @override
  List<Object?> get props => [message];
}

/// A fresh AES-256 key was generated; the UI should populate the key field.
///
/// This state is emitted and immediately replaced by [EncryptionFileSelected]
/// (or [EncryptionInitial] when no file is selected yet), so it acts as a
/// one-shot signal. The UI should use [BlocListener] to react to it.
final class EncryptionKeyGenerated extends EncryptionState {
  final String generatedKey;

  const EncryptionKeyGenerated({required this.generatedKey});

  @override
  List<Object?> get props => [generatedKey];
}

/// File was encrypted successfully.
final class EncryptionSuccess extends EncryptionState {
  /// The completed [EncryptedFile] record (also saved to Hive history).
  final EncryptedFile result;

  const EncryptionSuccess({required this.result});

  @override
  List<Object?> get props => [result];
}

/// File was decrypted successfully.
final class DecryptionSuccess extends EncryptionState {
  /// Absolute path where the recovered plaintext file was written.
  final String outputPath;

  const DecryptionSuccess({required this.outputPath});

  @override
  List<Object?> get props => [outputPath];
}

/// An error occurred during file picking, encryption, or decryption.
final class EncryptionError extends EncryptionState {
  final String message;

  const EncryptionError({required this.message});

  @override
  List<Object?> get props => [message];
}
