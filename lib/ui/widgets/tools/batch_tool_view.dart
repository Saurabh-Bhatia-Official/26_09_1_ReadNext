import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../services/file_service.dart';
import '../../../services/pdf/batch_processor_service.dart';
import '../../../services/pdf/pdf_watermark_service.dart';
import '../../../state/queue_provider.dart';

class BatchToolView extends ConsumerStatefulWidget {
  const BatchToolView({super.key});

  @override
  ConsumerState<BatchToolView> createState() => _BatchToolViewState();
}

class _BatchToolViewState extends ConsumerState<BatchToolView> {
  final List<String> _selectedFiles = [];
  BatchOperationType _operation = BatchOperationType.compress;
  bool _isProcessing = false;
  List<BatchItemProgress> _progressItems = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch PDF Processing'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Top action bar
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.note_add),
                  label: const Text('Select Batch PDFs'),
                  onPressed: _isProcessing ? null : _pickBatchFiles,
                ),
                const SizedBox(width: 12),
                if (_selectedFiles.isNotEmpty)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear'),
                    onPressed: _isProcessing ? null : () => setState(() => _selectedFiles.clear()),
                  ),
                const Spacer(),
                DropdownButton<BatchOperationType>(
                  value: _operation,
                  items: const [
                    DropdownMenuItem(value: BatchOperationType.compress, child: Text('Batch Compress')),
                    DropdownMenuItem(value: BatchOperationType.pdfToImages, child: Text('Batch PDF to Images')),
                    DropdownMenuItem(value: BatchOperationType.pdfToWord, child: Text('Batch PDF to Word (.docx)')),
                    DropdownMenuItem(value: BatchOperationType.pdfToExcel, child: Text('Batch PDF to Excel (.xlsx)')),
                    DropdownMenuItem(value: BatchOperationType.pdfToPowerPoint, child: Text('Batch PDF to PowerPoint (.pptx)')),
                    DropdownMenuItem(value: BatchOperationType.watermark, child: Text('Batch Watermark')),
                    DropdownMenuItem(value: BatchOperationType.ocr, child: Text('Batch OCR Searchable')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _operation = val);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Files Queue / Status
            Expanded(
              child: _progressItems.isNotEmpty
                  ? ListView.builder(
                      itemCount: _progressItems.length,
                      itemBuilder: (context, index) {
                        final item = _progressItems[index];
                        final isDone = item.status == 'Completed';
                        final isFailed = item.status == 'Failed';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDone
                                  ? Colors.green
                                  : isFailed
                                      ? Colors.red
                                      : theme.colorScheme.primary,
                              child: Icon(
                                isDone
                                    ? Icons.check
                                    : isFailed
                                        ? Icons.close
                                        : Icons.hourglass_top,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            title: Text(item.fileName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                if (item.status == 'Processing')
                                  const LinearProgressIndicator()
                                else
                                  Text(
                                    item.outputPath != null ? 'Saved to: ${item.outputPath}' : item.error ?? item.status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDone ? Colors.green : isFailed ? Colors.red : null,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : _selectedFiles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.dynamic_feed, size: 56, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              const Text('No batch files selected', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Select multiple PDF files to process simultaneously'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _selectedFiles.length,
                          itemBuilder: (context, index) {
                            final path = _selectedFiles[index];
                            return ListTile(
                              leading: Text('${index + 1}.'),
                              title: Text(p.basename(path)),
                              subtitle: Text(path),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => setState(() => _selectedFiles.removeAt(index)),
                              ),
                            );
                          },
                        ),
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              icon: const Icon(Icons.play_arrow),
              label: Text(
                'Run Batch Operation on ${_selectedFiles.length} Files',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: (_selectedFiles.isNotEmpty && !_isProcessing) ? _runBatch : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBatchFiles() async {
    final paths = await FileService.pickMultiplePdfFiles();
    setState(() {
      for (final p in paths) {
        if (!_selectedFiles.contains(p)) _selectedFiles.add(p);
      }
      _progressItems = [];
    });
  }

  Future<void> _runBatch() async {

    setState(() {
      _isProcessing = true;
      _progressItems = _selectedFiles.map((f) => BatchItemProgress(inputPath: f, fileName: p.basename(f))).toList();
    });

    try {
      final results = await BatchProcessorService.processBatch(
        filePaths: _selectedFiles,
        operation: _operation,
        watermarkConfig: const WatermarkConfig(text: 'BATCH CONFIDENTIAL'),
        onItemUpdated: (idx, total, item) {
          if (mounted) {
            setState(() {
              final targetIndex = _progressItems.indexWhere((p) => p.inputPath == item.inputPath);
              if (targetIndex >= 0) {
                _progressItems[targetIndex] = item;
              }
            });
          }
        },
      );

      setState(() => _progressItems = results);

      ref.read(queueProvider.notifier).clearNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Batch processing finished successfully!')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Batch failed: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
