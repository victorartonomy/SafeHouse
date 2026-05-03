# SafeHouse: Gemini CLI Context

This project is **SafeHouse**, a military-grade AES-256 file encryption application built with Flutter. It provides secure, on-device file encryption and decryption with local key management, biometric authentication, and category-aware cloud backups.

## Project Overview

*   **Goal:** Provide a secure environment for encrypting and decrypting files using AES-256 (CBC mode).
*   **Architecture:** Follows **Clean Architecture** principles with a clear separation of layers:
    *   **Domain:** Entities, Repositories (interfaces), and Use Cases.
    *   **Data:** Data sources (Hive, AES service, Firebase) and Repository implementations.
    *   **Presentation:** UI screens, Widgets, and BLoC/Cubit state management.
*   **Key Features:**
    *   **AES-256 Encryption:** Securely encrypts any file type.
    *   **Calculator Vault:** Disguises the app as a calculator; requires a secret code to unlock.
    *   **Category Management:** Organize files into categories with optional default passwords.
    *   **Cloud Backup:** Back up encrypted files to Firebase Storage, organized by category folders.
    *   **Encrypted History:** Stores a history of encrypted files in an AES-encrypted Hive box.
    *   **Secure Key Storage:** The Hive encryption key is stored in the OS-backed Keystore/Keychain.
    *   **Biometric Auth:** Gates access to sensitive areas like History and Cloud Backup.

## Tech Stack

*   **Framework:** Flutter (Dart)
*   *State Management:** `flutter_bloc` (using Cubits and Blocs)
*   **Dependency Injection:** `get_it` (Service Locator)
*   **Encryption Engine:** `encrypt` & `pointycastle`
*   **Local Persistence:** `hive` & `hive_flutter`
*   **Cloud Integration:** `firebase_core`, `firebase_auth`, `firebase_storage`
*   **Secure Storage:** `flutter_secure_storage`
*   **Permissions:** `permission_handler`
*   **Biometrics:** `local_auth`

## Program Flow

1.  **Initialization**: The app starts at `main.dart`, initializes Firebase, Hive, and the Service Locator (`injection_container.dart`).
2.  **Splash Screen**: `splash_screen.dart` determines if the user is logged in. If not, redirects to `login_screen.dart`.
3.  **Authentication**: Users authenticate via `AuthCubit` using Firebase Email or Google Sign-In.
4.  **The Vault (Calculator)**: Once authenticated, the app launches `calculator_screen.dart`. It behaves as a normal calculator. Entering a specific sequence (handled by `CheckUnlockSequenceUseCase`) triggers the transition to the main app.
5.  **Main Navigation**: `home_screen.dart` serves as the hub for Encrypt, Decrypt, History, Categories, and Cloud Backup.
6.  **Encryption**: User selects a file and a category (or manual key). `EncryptionCubit` uses `AesEncryptionService` to encrypt. Metadata is saved to `EncryptionLocalDataSource`.
7.  **Decryption**: User picks an `.enc` file and provides the key/password. `EncryptionCubit` recovers the plaintext.
8.  **Cloud Sync**: Users can upload files to Firebase via `CloudBackupCubit`. Files are organized in folders corresponding to their categories on Firebase Storage.

## File Structure & Descriptions

### Root `lib/`
*   `firebase_options.dart`: Firebase configuration for multiple platforms.
*   `injection_container.dart`: Service locator registration for dependency injection.
*   `main.dart`: App entry point and global theme definition.

### `lib/core/`
*   `errors/failures.dart`: Standard failure classes for error handling.
*   `permissions/storage_permission.dart`: Logic for handling Android 11+ storage permissions.
*   `storage/safe_house_paths.dart`: Utility for resolving local file paths on the device.
*   `theme/app_theme.dart`: (Internal) UI theme constants and style definitions.
*   `theme/theme_notifier.dart`: Manages app-wide theme state (dark/light mode).
*   `usecases/usecase.dart`: Base class for all domain use cases.

### `lib/features/auth/`
*   `data/datasources/auth_remote_datasource.dart`: Firebase Auth implementation.
*   `data/models/auth_user_model.dart`: Data model for authenticated users.
*   `data/repositories/auth_repository_impl.dart`: Implementation of the Auth repository.
*   `domain/entities/auth_user.dart`: Domain entity representing a user.
*   `domain/repositories/auth_repository.dart`: Interface for authentication operations.
*   `domain/usecases/`: Individual use cases for login, signup, and logout.
*   `presentation/cubits/auth_cubit.dart`: State management for the auth flow.
*   `presentation/pages/`: UI for Login, Signup, and Splash screens.

### `lib/features/calculator/`
*   `domain/entities/calculator_expression.dart`: Represents a mathematical expression.
*   `domain/usecases/check_unlock_sequence_usecase.dart`: Validates the secret vault code.
*   `domain/usecases/evaluate_expression_usecase.dart`: Handles calculator logic.
*   `presentation/bloc/calculator_bloc.dart`: Manages calculator state and transitions.
*   `presentation/pages/calculator_screen.dart`: The functional calculator UI (the "Vault door").
*   `presentation/widgets/`: Keypad and display widgets for the calculator.

### `lib/features/categories/`
*   `data/datasources/category_local_datasource.dart`: Hive-backed storage for categories.
*   `data/models/category_model.dart`: Hive-annotated model for categories.
*   `data/repositories/category_repository_impl.dart`: Repository for category CRUD operations.
*   `domain/entities/category.dart`: Entity representing a user-defined category.
*   `domain/repositories/category_repository.dart`: Interface for category management.
*   `domain/usecases/`: Use cases for adding, updating, and deleting categories.
*   `presentation/bloc/category_bloc.dart`: State management for categories.
*   `presentation/pages/categories_screen.dart`: UI for managing file categories.
*   `presentation/widgets/`: Category picker and password prompt components.

### `lib/features/cloud/`
*   `data/datasources/cloud_remote_datasource.dart`: Firebase Storage implementation with folder support.
*   `data/repositories/cloud_repository_impl.dart`: Repository for cloud file transfers.
*   `domain/entities/cloud_file.dart`: Represents a file stored in the cloud.
*   `domain/entities/cloud_transfer.dart`: Tracks progress of uploads and downloads.
*   `domain/repositories/cloud_repository.dart`: Interface for cloud operations.
*   `presentation/cubits/cloud_backup_cubit.dart`: Manages cloud file lists and transfers.
*   `presentation/pages/cloud_backup_screen.dart`: UI for folder-based cloud backups.

### `lib/features/encryption/`
*   `data/datasources/aes_encryption_service.dart`: The core AES-256 encryption engine.
*   `data/datasources/encryption_local_datasource.dart`: Stores encryption history in Hive.
*   `data/models/encrypted_file_model.dart`: Data model for encryption records.
*   `data/repositories/encryption_repository_impl.dart`: Repository for encryption tasks.
*   `domain/entities/encrypted_file.dart`: Entity representing a processed file.
*   `domain/repositories/encryption_repository.dart`: Interface for encryption tasks.
*   `presentation/cubits/`: State management for encryption, decryption, and history.
*   `presentation/pages/`: UI for Home, Encrypt, Decrypt, and History screens.
*   `presentation/widgets/`: Reusable cards and tiles for file operations.

### `lib/features/settings/`
*   `presentation/cubits/settings_cubit.dart`: Manages user settings and theme toggles.
*   `presentation/pages/settings_screen.dart`: UI for app configurations and account management.

## Development Conventions

*   **Clean Architecture:** Maintain strict separation between layers.
*   **Security:** Never store raw keys. Use `AesEncryptionService` for all processing.
*   **State Management:** Blocs/Cubits are registered as factories in DI to ensure fresh state.
