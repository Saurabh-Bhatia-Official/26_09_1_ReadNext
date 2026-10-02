import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/file_service.dart';
import '../../../services/ocr/ocr_service.dart';
import '../../../state/queue_provider.dart';

class OcrToolView extends ConsumerStatefulWidget {
  const OcrToolView({super.key});

  @override
  ConsumerState<OcrToolView> createState() => _OcrToolViewState();
}

class _OcrToolViewState extends ConsumerState<OcrToolView> {
  String? _selectedFilePath;
  OcrLanguage _selectedLanguage = OcrLanguage.english;
  bool _isProcessing = false;
  double _progress = 0.0;
  List<OcrPageResult> _ocrResults = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Text Extraction'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // File Intake Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.document_scanner, color: Colors.deepOrange, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFilePath != null ? FileService.getFileName(_selectedFilePath!) : 'No document selected',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedFilePath ?? 'Select scanned PDF or Image (PNG, JPG, TIFF) for text extraction',
                              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.folder_open),
                        label: Text(_selectedFilePath == null ? 'Select Document' : 'Change'),
                        onPressed: _pickFile,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Language Selector
              Text('Select Document Language', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildLanguageCard(
                      lang: OcrLanguage.english,
                      title: 'English',
                      subtitle: 'Latin script, western documents',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLanguageCard(
                      lang: OcrLanguage.hindi,
                      title: 'Hindi (हिंदी)',
                      subtitle: 'Devanagari script, national standard',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLanguageCard(
                      lang: OcrLanguage.marathi,
                      title: 'Marathi (मराठी)',
                      subtitle: 'Devanagari script, regional standard',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (_isProcessing) ...[
                LinearProgressIndicator(value: _progress > 0 ? _progress : null),
                const SizedBox(height: 8),
                Text('Performing offline OCR: ${(_progress * 100).toInt()}%', textAlign: TextAlign.center),
                const SizedBox(height: 16),
              ],

              FilledButton.icon(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                icon: const Icon(Icons.document_scanner),
                label: const Text('Extract Text with OCR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: (_selectedFilePath != null && !_isProcessing) ? _runOcr : null,
              ),

              // Extracted Text Results Display
              if (_ocrResults.isNotEmpty) ...[
                const SizedBox(height: 28),
                Row(
                  children: [
                    Text('Extracted Text Content', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy All Text'),
                      onPressed: _copyAllText,
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Save as Searchable PDF'),
                      onPressed: _saveSearchablePdf,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ..._ocrResults.map((pageRes) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Page ${pageRes.pageNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Confidence: ${(pageRes.confidence * 100).toInt()}%',
                                  style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                tooltip: 'Copy Page Text',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: pageRes.extractedText));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Page text copied!')));
                                },
                              ),
                            ],
                          ),
                          const Divider(),
                          SelectableText(
                            pageRes.extractedText,
                            style: const TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required OcrLanguage lang,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedLanguage == lang;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedLanguage = lang),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.08) : theme.cardColor,
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final path = await FileService.pickDocumentOrImageFile();
    if (path != null) {
      setState(() {
        _selectedFilePath = path;
        _ocrResults = [];
      });
    }
  }

  Future<void> _runOcr() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.05;
      _ocrResults = [];
    });

    final taskId = ref.read(queueProvider.notifier).enqueueTask(
      title: 'OCR ${FileService.getFileName(_selectedFilePath!)}',
      operationName: 'OCR',
    );
    ref.read(queueProvider.notifier).startProcessing(taskId);

    try {
      final bytes = await File(_selectedFilePath!).readAsBytes();
      final results = await OcrService.performOcr(
        inputBytes: bytes,
        language: _selectedLanguage,
        onProgress: (p) {
          setState(() => _progress = p);
          ref.read(queueProvider.notifier).updateProgress(taskId, p);
        },
      );

      setState(() => _ocrResults = results);
      ref.read(queueProvider.notifier).completeTask(taskId, outputPath: _selectedFilePath!, successMessage: 'OCR completed successfully.');
    } catch (e) {
      ref.read(queueProvider.notifier).failTask(taskId, error: e.toString());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OCR failed: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _copyAllText() {
    final fullText = _ocrResults.map((r) => '--- Page ${r.pageNumber} ---\n${r.extractedText}').join('\n\n');
    Clipboard.setData(ClipboardData(text: fullText));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All document text copied to clipboard.')));
  }

  Future<void> _saveSearchablePdf() async {
    if (_selectedFilePath == null || _ocrResults.isEmpty) return;
    try {
      final bytes = await File(_selectedFilePath!).readAsBytes();
      final searchableBytes = await OcrService.createSearchablePdf(
        originalBytes: bytes,
        ocrResults: _ocrResults,
      );

      final savePath = await FileService.savePdfFile(
        fileName: '${FileService.getFileName(_selectedFilePath!).replaceAll('.pdf', '')}_searchable.pdf',
        bytes: searchableBytes,
        dialogTitle: 'Save Searchable PDF',
      );

      if (savePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Searchable PDF saved to $savePath')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}
