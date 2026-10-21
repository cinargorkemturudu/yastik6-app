import 'package:flutter/material.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';

/// Asks for the backup passphrase. Returns null when cancelled.
/// For a new backup ([isRestore] false) the passphrase is entered twice and must be at least [minLength] characters.
class BackupPassphraseDialog extends StatefulWidget {
  static const int minLength = 8;

  final bool isRestore;

  const BackupPassphraseDialog({super.key, required this.isRestore});

  static Future<String?> show(BuildContext context, {required bool isRestore}) {
    return showDialog<String>(
      context: context,
      builder: (_) => BackupPassphraseDialog(isRestore: isRestore),
    );
  }

  @override
  State<BackupPassphraseDialog> createState() => _BackupPassphraseDialogState();
}

class _BackupPassphraseDialogState extends State<BackupPassphraseDialog> {
  final _passphrase = TextEditingController();
  final _confirmation = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _passphrase.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  String? _validate(String passphrase) {
    if (widget.isRestore) {
      return passphrase.isEmpty ? "Lütfen yedekleme parolanızı girin." : null;
    }
    if (passphrase.length < BackupPassphraseDialog.minLength) {
      return "Parola en az ${BackupPassphraseDialog.minLength} karakter olmalı.";
    }
    return passphrase == _confirmation.text ? null : "Parolalar eşleşmiyor.";
  }

  void _submit() {
    final passphrase = _passphrase.text;
    final error = _validate(passphrase);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, passphrase);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isRestore ? "Verileri Geri Yükle?" : "Yedekleme Parolası",
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isRestore
                  ? "Buluttaki yedeğiniz indirilecek ve cihazdaki mevcut verilerinizin üzerine yazılacaktır. Bu işlem geri alınamaz. Yedeği alırken belirlediğiniz parolayı girin."
                  : "Yedeğiniz bu parolayla şifrelenir; yeni bir telefona geri yüklerken de bu parola gerekir. Parolanızı unutursanız yedeğiniz kurtarılamaz.",
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('backup_passphrase'),
              controller: _passphrase,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: "Parola"),
              onSubmitted: (_) => widget.isRestore ? _submit() : null,
            ),
            if (!widget.isRestore)
              TextField(
                key: const Key('backup_passphrase_confirmation'),
                controller: _confirmation,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Parola (tekrar)"),
                onSubmitted: (_) => _submit(),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.lossAccent),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("İptal"),
        ),
        TextButton(
          onPressed: _submit,
          child: widget.isRestore
              ? const Text(
                  "Geri Yükle",
                  style: TextStyle(color: AppColors.lossAccent),
                )
              : const Text("Yedekle"),
        ),
      ],
    );
  }
}
