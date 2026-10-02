import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/file_service.dart';
import '../../../services/pdf/pdf_metadata_service.dart';
import '../../../state/document_provider.dart';

class MetadataToolView extends ConsumerStatefulWidget {
  const MetadataToolView({super.key});

  @override
  ConsumerState<MetadataToolView> createState() => _MetadataToolViewState();
}

class _MetadataToolViewState extends ConsumerState<MetadataToolView> {
  String? _selectedFilePath;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _keywordsController = TextEditingController();
  final TextEditingController _creatorController = TextEditingController(text: 'ReadNext by Complex Innovators');
  final TextEditingController _producerController = TextEditingController(text: 'ReadNext Engine');

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _subjectController.dispose();
    _keywordsController.dispose();
    _creatorController.dispose();
    _producerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Metadata & Properties Editor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.info_outline, color: Colors.blueGrey, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFilePath != null ? FileService.getFileName(_selectedFilePath!) : 'No PDF selected',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedFilePath ?? 'Select a PDF to view and edit internal document metadata',
                              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.folder_open),
                        label: Text(_selectedFilePath == null ? 'Select PDF' : 'Change'),
                        onPressed: _isLoading ? null : _pickPdf,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (_selectedFilePath != null) ...[
                Text('Document Metadata Fields', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Document Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _authorController,
                  decoration: const InputDecoration(
                    labelText: 'Author',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.subject),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _keywordsController,
                  decoration: const InputDecoration(
                    labelText: 'Keywords (Comma-separated)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _creatorController,
                  decoration: const InputDecoration(
                    labelText: 'Creator Application',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.code),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _producerController,
                  decoration: const InputDecoration(
                    labelText: 'Producer Tool',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.build_circle_outlined),
                  ),
                ),

                const SizedBox(height: 24),

                if (_isSaving) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                ],

                FilledButton.icon(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: const Icon(Icons.save),
                  label: const Text('Save Updated Metadata', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: _isSaving ? null : _saveMetadata,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPdf() async {
    final path = await FileService.pickPdfFile();
    if (path != null) {
      setState(() {
        _selectedFilePath = path;
        _isLoading = true;
      });

      try {
        final bytes = await File(path).readAsBytes();
        final meta = await PdfMetadataService.readMetadata(bytes);

        setState(() {
          _titleController.text = meta.title.isNotEmpty ? meta.title : FileService.getFileName(path);
          _authorController.text = meta.author;
          _subjectController.text = meta.subject;
          _keywordsController.text = meta.keywords;
          _creatorController.text = meta.creator;
          _producerController.text = meta.producer;
          _isLoading = false;
        });
      } catch (_) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveMetadata() async {
    if (_selectedFilePath == null) return;
    setState(() => _isSaving = true);

    try {
      final bytes = await File(_selectedFilePath!).readAsBytes();
      final updatedMeta = EditablePdfMetadata(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        subject: _subjectController.text.trim(),
        keywords: _keywordsController.text.trim(),
        creator: _creatorController.text.trim(),
        producer: _producerController.text.trim(),
      );

      final updatedBytes = await PdfMetadataService.updateMetadata(
        pdfBytes: bytes,
        metadata: updatedMeta,
      );

      final savePath = await FileService.savePdfFile(
        fileName: '${FileService.getFileName(_selectedFilePath!).replaceAll('.pdf', '')}_metadata.pdf',
        bytes: updatedBytes,
        dialogTitle: 'Save PDF with New Metadata',
      );

      if (savePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved metadata to $savePath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => ref.read(documentProvider.notifier).openFile(savePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
