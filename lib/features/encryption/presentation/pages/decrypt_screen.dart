import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

import '../../../../core/permissions/storage_permission.dart';
import '../../../../injection_container.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/usecases/derive_key_usecase.dart';
import '../../../categories/presentation/widgets/category_picker.dart';
import '../../../categories/presentation/widgets/password_prompt_dialog.dart';
import '../cubits/encryption_cubit.dart';
import '../widgets/file_picker_tile.dart';
import '../widgets/key_field.dart';
import '../widgets/result_card.dart';

class DecryptScreen extends StatefulWidget {
  const DecryptScreen({super.key});

  /// Returns a [MaterialPageRoute] that provides a fresh [EncryptionCubit].
  static Route<void> route() => MaterialPageRoute(
    builder: (_) => BlocProvider(
      create: (_) => sl<EncryptionCubit>(),
      child: const DecryptScreen(),
    ),
  );

  @override
  State<DecryptScreen> createState() => _DecryptScreenState();
}

class _DecryptScreenState extends State<DecryptScreen> {
  final _keyController = TextEditingController();
  Category? _selectedCategory;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  /// Same All-Files-Access check the encrypt screen does — without it
  /// we can neither read the user-picked encrypted file nor write the
  /// recovered plaintext to /storage/emulated/0/SafeHouse/decrypted files/.
  Future<void> _onDecryptPressed(
    BuildContext context,
    EncryptionCubit cubit,
  ) async {
    final granted = await StoragePermission.ensure(context);
    if (!granted) return;
    if (!context.mounted) return;

    final category = _selectedCategory;

    if (category != null) {
      final password = await PasswordPromptDialog.show(
        context,
        categoryName: category.name,
        title: 'Enter category password',
        confirmLabel: 'Decrypt',
      );
      if (password == null || password.isEmpty) return;
      if (!context.mounted) return;

      final derivedKey = sl<DeriveKeyUseCase>().call(
        password: password,
        salt: category.salt,
      );
      cubit.decryptSelectedFile(derivedKey);
    } else {
      cubit.decryptSelectedFile(_keyController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decrypt File'),
        leading: const BackButton(),
      ),
      body: BlocConsumer<EncryptionCubit, EncryptionState>(
        listenWhen: (_, current) => current is EncryptionError,
        listener: (context, state) {
          if (state is EncryptionError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(
                    0xFFFF4D4D,
                  ).withValues(alpha: 0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
          }
        },
        builder: (context, state) {
          // ── Success view ─────────────────────────────────────────────
          if (state is DecryptionSuccess) {
            return _DecryptSuccessView(
              outputPath: state.outputPath,
              onDecryptAnother: () => context.read<EncryptionCubit>().reset(),
            );
          }

          final cubit = context.read<EncryptionCubit>();
          final loadingState = state is EncryptionLoading ? state : null;
          final isLoading = loadingState != null;
          final selectedFile = state is EncryptionFileSelected ? state : null;

          // ── Form view ────────────────────────────────────────────────
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick an encrypted file and provide the original secret key.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),

                // Step 1 — File picker
                _SectionLabel(number: '01', label: 'Choose Encrypted File'),
                const SizedBox(height: 10),
                FilePickerTile(
                  fileName: selectedFile?.fileName,
                  filePath: selectedFile?.filePath,
                  label: 'Pick an encrypted file',
                  onTap: isLoading
                      ? () {}
                      : () => cubit.pickFileForDecryption(),
                ),
                const SizedBox(height: 28),

                // Step 2 — Category or Secret Key
                _SectionLabel(
                  number: '02',
                  label: _selectedCategory == null
                      ? 'Category or Secret Key'
                      : 'Category',
                ),
                const SizedBox(height: 10),
                CategoryPicker(
                  value: _selectedCategory,
                  enabled: !isLoading,
                  onChanged: (cat) =>
                      setState(() => _selectedCategory = cat),
                ),
                if (_selectedCategory == null) ...[
                  const SizedBox(height: 16),
                  KeyField(
                    controller: _keyController,
                    label: 'Secret Key',
                    hint: 'Paste the AES-256 key used during encryption',
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    'You will be prompted for the category password.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 36),

                // CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FC3F7),
                      foregroundColor: const Color(0xFF0D0D0D),
                    ),
                    onPressed: isLoading
                        ? null
                        : () => _onDecryptPressed(context, cubit),
                    child: isLoading
                        ? _LoadingRow(message: loadingState.message)
                        : Text(
                            _selectedCategory == null
                                ? 'Decrypt File'
                                : 'Decrypt with ${_selectedCategory!.name}',
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Success view ───────────────────────────────────────────────────────────

class _DecryptSuccessView extends StatelessWidget {
  final String outputPath;
  final VoidCallback onDecryptAnother;

  const _DecryptSuccessView({
    required this.outputPath,
    required this.onDecryptAnother,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResultCard(
            isSuccess: true,
            title: 'File Decrypted',
            subtitle: 'The original file has been recovered.',
          ),
          const SizedBox(height: 20),
          ResultCard(
            isSuccess: true,
            title: p.basename(outputPath),
            subtitle: 'Saved to device',
            copyableValue: outputPath,
            copyLabel: 'Path',
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onDecryptAnother,
              child: const Text('Decrypt Another File'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers (local copies kept here to avoid cross-file coupling) ───

class _SectionLabel extends StatelessWidget {
  final String number;
  final String label;

  const _SectionLabel({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = const Color(0xFF4FC3F7);
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.titleMedium),
      ],
    );
  }
}

class _LoadingRow extends StatelessWidget {
  final String message;
  const _LoadingRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF0D0D0D),
          ),
        ),
        const SizedBox(width: 10),
        Text(message),
      ],
    );
  }
}
