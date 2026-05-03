import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/theme_notifier.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'features/auth/domain/usecases/sign_out_usecase.dart';
import 'features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import 'features/auth/domain/usecases/delete_account_usecase.dart';
import 'features/auth/presentation/cubits/auth_cubit.dart';
import 'features/cloud/data/datasources/cloud_remote_datasource.dart';
import 'features/cloud/data/repositories/cloud_repository_impl.dart';
import 'features/cloud/domain/repositories/cloud_repository.dart';
import 'features/cloud/presentation/cubits/cloud_backup_cubit.dart';
import 'features/settings/presentation/cubits/settings_cubit.dart';
import 'features/encryption/data/datasources/aes_encryption_service.dart';
import 'features/encryption/data/datasources/encryption_local_datasource.dart';
import 'features/encryption/data/repositories/encryption_repository_impl.dart';
import 'features/encryption/domain/entities/encrypted_file.dart';
import 'features/encryption/domain/repositories/encryption_repository.dart';
import 'features/encryption/presentation/cubits/encryption_cubit.dart';
import 'features/encryption/presentation/cubits/history_cubit.dart';
import 'features/calculator/domain/usecases/check_unlock_sequence_usecase.dart';
import 'features/calculator/domain/usecases/evaluate_expression_usecase.dart';
import 'features/calculator/presentation/bloc/calculator_bloc.dart';
import 'features/categories/data/datasources/category_local_datasource.dart';
import 'features/categories/data/models/category_model.dart';
import 'features/categories/data/repositories/category_repository_impl.dart';
import 'features/categories/domain/repositories/category_repository.dart';
import 'features/categories/domain/usecases/add_category_usecase.dart';
import 'features/categories/domain/usecases/delete_category_usecase.dart';
import 'features/categories/domain/usecases/derive_key_usecase.dart';
import 'features/categories/domain/usecases/get_categories_usecase.dart';
import 'features/categories/domain/usecases/update_category_usecase.dart';
import 'features/categories/presentation/bloc/category_bloc.dart';

/// Global service-locator instance.
/// Access registered objects anywhere via `sl<MyType>()`.
final GetIt sl = GetIt.instance;

/// Key under which the Hive box's AES cipher key is stored in the
/// platform secure storage (Android Keystore / iOS Keychain).
const _kHiveCipherKeyAlias = 'safehouse.hive.cipher.v1';

/// Registers all dependencies in dependency order.
///
/// Called once in [main] before [runApp], after Hive is initialised and
/// adapters are registered.
Future<void> init() async {
  // ── Firebase & External ───────────────────────────────────────────────────
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
  sl.registerLazySingleton(() => FirebaseStorage.instance);

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // ── Secure storage ────────────────────────────────────────────────────────
  // Stored on Android via EncryptedSharedPreferences (Keystore-backed) and
  // on iOS via the Keychain. Survives app updates; wiped on uninstall on
  // Android by default.
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Hive cipher key ───────────────────────────────────────────────────────
  // Generate a fresh 256-bit key on first launch and persist it in secure
  // storage; reuse it on subsequent launches.
  final cipherKey = await _readOrCreateHiveCipherKey(secureStorage);

  // ── Hive boxes ────────────────────────────────────────────────────────────
  // Open the box here so it's ready before any datasource is constructed.
  // Using HiveAesCipher means the on-disk file is opaque — secret keys
  // can no longer be read by anyone with filesystem access.
  final encryptedFilesBox = await Hive.openBox<EncryptedFile>(
    EncryptionLocalDataSourceImpl.boxName,
    encryptionCipher: HiveAesCipher(cipherKey),
  );
  final categoriesBox = await Hive.openBox<CategoryModel>(
    CategoryLocalDataSourceImpl.boxName,
    encryptionCipher: HiveAesCipher(cipherKey),
  );

  // ── Services ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AesEncryptionService>(() => AesEncryptionService());

  // ── Data sources ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<EncryptionLocalDataSource>(
    () => EncryptionLocalDataSourceImpl(box: encryptedFilesBox),
  );

  sl.registerLazySingleton<CategoryLocalDataSource>(
    () => CategoryLocalDataSourceImpl(box: categoriesBox),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl(), googleSignIn: sl()),
  );

  sl.registerLazySingleton<CloudRemoteDataSource>(
    () => CloudRemoteDataSourceImpl(
      firebaseStorage: sl(),
      firebaseAuth: sl(),
      sharedPreferences: sl(),
    ),
  );

  sl.registerLazySingleton(() => ThemeNotifier(prefs: sl()));

  // ── Repositories ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<EncryptionRepository>(
    () => EncryptionRepositoryImpl(
      encryptionService: sl<AesEncryptionService>(),
      localDataSource: sl<EncryptionLocalDataSource>(),
    ),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<CloudRepository>(
    () => CloudRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(local: sl<CategoryLocalDataSource>()),
  );

  // ── Use Cases ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => SignInWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => SignUpWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => SignInWithGoogleUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAccountUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

  // Calculator
  sl.registerLazySingleton(() => EvaluateExpressionUseCase());
  sl.registerLazySingleton(() => CheckUnlockSequenceUseCase());

  // Categories
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => AddCategoryUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCategoryUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCategoryUseCase(sl()));
  sl.registerLazySingleton(() => DeriveKeyUseCase());

  // ── Cubits ────────────────────────────────────────────────────────────────
  // Factories ensure each screen receives a fresh instance with clean state.
  sl.registerFactory<EncryptionCubit>(
    () => EncryptionCubit(repository: sl<EncryptionRepository>()),
  );
  sl.registerFactory<HistoryCubit>(
    () => HistoryCubit(repository: sl<EncryptionRepository>()),
  );
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      signInWithEmail: sl(),
      signUpWithEmail: sl(),
      signInWithGoogle: sl(),
      signOut: sl(),
      deleteAccount: sl(),
      getCurrentUser: sl(),
    ),
  );
  sl.registerLazySingleton<SettingsCubit>(
    () => SettingsCubit(
      cloudRepository: sl(),
      authCubit: sl(),
      themeNotifier: sl(),
    ),
  );
  sl.registerLazySingleton<CloudBackupCubit>(
    () => CloudBackupCubit(cloudRepository: sl()),
  );
  sl.registerFactory<CalculatorBloc>(
    () => CalculatorBloc(evaluate: sl(), checkUnlock: sl()),
  );
  sl.registerLazySingleton<CategoryBloc>(
    () => CategoryBloc(
      getAll: sl(),
      add: sl(),
      update: sl(),
      delete: sl(),
    ),
  );
}

/// Reads the Hive cipher key from secure storage, generating and persisting
/// one on first launch. The key is the 32-byte payload that
/// [HiveAesCipher] expects.
Future<List<int>> _readOrCreateHiveCipherKey(
  FlutterSecureStorage secureStorage,
) async {
  final existing = await secureStorage.read(key: _kHiveCipherKeyAlias);
  if (existing != null) {
    final bytes = base64Decode(existing);
    if (bytes.length == 32) return bytes;
    // Length mismatch: fall through and regenerate. (Shouldn't happen in
    // normal operation; defensive against partially-written secure storage.)
  }

  final fresh = Hive.generateSecureKey(); // 32 random bytes
  await secureStorage.write(
    key: _kHiveCipherKeyAlias,
    value: base64Encode(fresh),
  );
  return fresh;
}
