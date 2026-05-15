# SafeHouse 🛡️

Military-grade AES-256 file encryption application built with Flutter. SafeHouse provides secure, on-device file encryption and decryption with local key management, biometric authentication, and category-aware cloud backups.

## ✨ Key Features

*   **AES-256 Encryption:** Securely encrypts and decrypts any file type using AES-256 (CBC mode).
*   **Category Management:** Group files logically (e.g., Personal, Work, Bank) and assign default passwords for seamless auto-encryption.
*   **Cloud Backup:** Securely backup and retrieve your encrypted files to Firebase Storage, organized cleanly into category-based folders.
*   **Encrypted History:** Keeps a local, encrypted record of your operations using a Hive box secured by the OS Keystore/Keychain.
*   **Biometric Authentication:** Gates access to sensitive areas of the app like your encryption history and cloud backups.
*   **Local First:** No raw keys are ever stored in plaintext. Passwords and keys are derived and used strictly in memory.

## 🏗️ Architecture

The project strictly follows **Clean Architecture** principles with a clear separation of layers:
*   **Domain:** Core business logic, Entities, and Use Cases.
*   **Data:** Repository implementations, Hive local storage, Firebase remote storage, and AES-256 service.
*   **Presentation:** Screen UIs and state management powered by `flutter_bloc` (Cubits/Blocs).

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (^3.10.4)
*   Android Studio / Xcode for mobile builds

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/safe_house.git
    cd safe_house
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Generate Hive Adapters:**
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

4.  **Run the app:**
    ```bash
    flutter run
    ```

## 🧪 Testing

To run the suite of unit and widget tests:
```bash
flutter test
```

## ⚙️ CI/CD

This repository includes GitHub Actions workflows:

* **CI (`.github/workflows/ci.yml`)**
  * Runs on pull requests and pushes to `main`/`master`.
  * Installs dependencies, checks formatting, runs `flutter analyze`, and runs `flutter test`.
* **CD (`.github/workflows/cd.yml`)**
  * Runs manually (`workflow_dispatch`) or on tags matching `v*` (for example `v1.0.0`).
  * Builds a release Android APK.
  * Uploads the APK as a workflow artifact.
  * On version tags, also creates/updates a GitHub Release and attaches the APK.

## 🔒 Security Notice

SafeHouse is designed as a secure vault for your files. Please remember to securely store your **Secret Keys** or **Category Passwords**. If you lose your key/password, the encrypted files cannot be recovered.
