import 'package:flutter/material.dart';

class GoToPageDialog extends StatefulWidget {
  final int currentPage;
  final int totalPages;

  const GoToPageDialog({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  static Future<int?> show(BuildContext context, int currentPage, int totalPages) {
    return showDialog<int>(
      context: context,
      builder: (context) => GoToPageDialog(
        currentPage: currentPage,
        totalPages: totalPages,
      ),
    );
  }

  @override
  State<GoToPageDialog> createState() => _GoToPageDialogState();
}

class _GoToPageDialogState extends State<GoToPageDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentPage.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final page = int.tryParse(_controller.text);
    if (page == null || page < 1 || page > widget.totalPages) {
      setState(() {
        _error = 'Enter a valid page between 1 and ${widget.totalPages}';
      });
      return;
    }
    Navigator.of(context).pop(page);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Go to Page'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Page Number (1 - ${widget.totalPages})',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Go'),
        ),
      ],
    );
  }
}
