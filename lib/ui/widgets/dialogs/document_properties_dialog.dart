import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/pdf_document_meta.dart';

class DocumentPropertiesDialog extends StatelessWidget {
  final PdfDocumentMeta metadata;

  const DocumentPropertiesDialog({super.key, required this.metadata});

  static Future<void> show(BuildContext context, PdfDocumentMeta metadata) {
    return showDialog(
      context: context,
      builder: (context) => DocumentPropertiesDialog(metadata: metadata),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Document Properties'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRow('Title', metadata.title.isNotEmpty ? metadata.title : 'Untitled', theme),
              _buildRow('Author', metadata.author.isNotEmpty ? metadata.author : 'Unknown', theme),
              _buildRow('Subject', metadata.subject.isNotEmpty ? metadata.subject : 'None', theme),
              _buildRow('Keywords', metadata.keywords.isNotEmpty ? metadata.keywords : 'None', theme),
              _buildRow('Creator', metadata.creator.isNotEmpty ? metadata.creator : 'ReadNext PDF Engine', theme),
              _buildRow('PDF Version', metadata.pdfVersion, theme),
              _buildRow('Page Count', '${metadata.pageCount} pages', theme),
              _buildRow('File Size', Formatters.formatBytes(metadata.fileSize), theme),
              _buildRow('Location', metadata.filePath.isNotEmpty ? metadata.filePath : 'In-Memory Stream', theme),
              if (metadata.creationDate != null)
                _buildRow('Created', Formatters.formatDate(metadata.creationDate!), theme),
              if (metadata.modificationDate != null)
                _buildRow('Modified', Formatters.formatDate(metadata.modificationDate!), theme),
              _buildRow('Encrypted', metadata.isEncrypted ? 'Yes (Protected)' : 'No', theme),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

