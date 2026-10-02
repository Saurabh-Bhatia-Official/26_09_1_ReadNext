import 'package:flutter/material.dart';

class PasswordPromptDialog extends StatefulWidget {
  final String fileName;

  const PasswordPromptDialog({super.key, required this.fileName});

  static Future<String?> show(BuildContext context, String fileName) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordPromptDialog(fileName: fileName),
    );
  }

  @override
  State<PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<PasswordPromptDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.amber),
          SizedBox(width: 8),
          Text('Password Protected PDF'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The document "${widget.fileName}" is encrypted. Please enter the password to open it.',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Document Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (val) => Navigator.of(context).pop(val),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Unlock'),
        ),
      ],
    );
  }
}
