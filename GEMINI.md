# SafeHouse: Gemini CLI Context

This project is **SafeHouse**, a military-grade AES-256 file encryption application built with Flutter. It was developed as a final year project to provide secure, on-device file encryption and decryption with local key management.

## Project Overview

*   **Goal:** Provide a secure environment for encrypting and decrypting files using AES-256 (CBC mode).
*   **Architecture:** Follows **Clean Architecture** principles with a clear separation of layers:
    *   **Domain:** Entities (`EncryptedFile`), Repositories (interfaces), and Use Cases (though many are currently handled directly by Cubits).
    *   **Data:** Data sources (Hive, AES service) and Repository implementations.
    *   **Presentation:** UI screens and BLoC/Cubit state management.
*   **Key Features:**
    *   **AES-256 Encryption:** Securely encrypts any file type.
    *   **Decryption:** Recovers files using the stored or manually entered secret keys.
    *   **Encrypted History:** Stores a history of encrypted files in an AES-encrypted Hive box.
    *   **Secure Key Storage:** The Hive encryption key is stored in the OS-backed Keystore/Keychain via `flutter_secure_storage`.
    *   **Biometric Auth:** Gates access to sensitive areas like the History screen.
    *   **Storage Management:** Handles complex Android 11+ `MANAGE_EXTERNAL_STORAGE` permissions.

## Tech Stack

*   **Framework:** Flutter (Dart)
*   **State Management:** `flutter_bloc` (using Cubits)
*   **Dependency Injection:** `get_it` (Service Locator)
*   **Encryption Engine:** `encrypt` & `pointycastle`
*   **Local Persistence:** `hive` & `hive_flutter`
*   **Secure Storage:** `flutter_secure_storage`
*   **Permissions:** `permission_handler`
*   **Biometrics:** `local_auth`

## Building and Running

### Prerequisites
*   Flutter SDK (^3.10.4)
*   Android Studio / Xcode for mobile builds

### Key Commands
*   **Fetch dependencies:**
    ```bash
    flutter pub get
    ```
*   **Generate Hive Adapters:**
    The project uses `hive_generator`. Run this after modifying entities in `lib/features/encryption/domain/entities/`:
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
*   **Run the App:**
    ```bash
    flutter run
    ```
*   **Run Tests:**
    ```bash
    flutter test
    ```

## Development Conventions

*   **Clean Architecture:** Maintain the separation between Data, Domain, and Presentation layers. Avoid leaking implementation details (like Hive) into the Domain layer where possible (though `EncryptedFile` currently uses Hive annotations for convenience).
*   **State Management:** Use Cubits for screen-level state. Register them as `factories` in `injection_container.dart` to ensure fresh state on navigation.
*   **Dependency Injection:** Access services, repositories, and cubits via the `sl` (Service Locator) instance.
*   **Error Handling:** Use `Failure` classes in `lib/core/errors/` to propagate errors from Data/Domain layers to the UI.
*   **Security:** Never store raw secret keys in plaintext on disk. Always use the encrypted Hive box or Secure Storage.
*   **UI/UX:** Adheres to a custom dark-themed Material 3 design (see `lib/main.dart` for the theme definition).

## Directory Structure Highlights

*   `lib/core/`: Cross-cutting concerns like errors, permissions, and use case base classes.
*   `lib/features/encryption/`: The primary feature module.
    *   `data/datasources/`: Interfaces and implementations for AES encryption and Hive storage.
    *   `domain/entities/`: Core data models like `EncryptedFile`.
    *   `presentation/cubits/`: State management logic.
    *   `presentation/pages/`: UI screens (Home, Encrypt, Decrypt, History).
*   `assets/`: Contains `logo.png` used for the app icon.
