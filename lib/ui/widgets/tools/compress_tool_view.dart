import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/file_service.dart';
import '../../../services/pdf/pdf_compressor_service.dart';
import '../../../state/document_provider.dart';
import '../../../state/queue_provider.dart';

class CompressToolView extends ConsumerStatefulWidget {
  const CompressToolView({super.key});

  @override
  ConsumerState<CompressToolView> createState() => _CompressToolViewState();
}

class _CompressToolViewState extends ConsumerState<CompressToolView> {
  String? _selectedFilePath;
  int _originalSizeBytes = 0;
  CompressionLevel _level = CompressionLevel.medium;
  final double _customScale = 1.0;

  bool _isProcessing = false;
  double _progress = 0.0;
  CompressionResult? _result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compress PDF File'),
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
              // File Selector Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.compress, color: Colors.teal, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFilePath != null
                                  ? FileService.getFileName(_selectedFilePath!)
                                  : 'No PDF selected',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedFilePath != null
                                  ? 'Current Size: ${_formatBytes(_originalSizeBytes)}'
                                  : 'Choose a large PDF to reduce file size while preserving quality',
                              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.folder_open),
                        label: Text(_selectedFilePath == null ? 'Select PDF' : 'Change PDF'),
                        onPressed: _isProcessing ? null : _pickPdf,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (_selectedFilePath != null) ...[
                Text('Select Compression Level', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // Compression level selection cards
                Row(
                  children: [
                    Expanded(
                      child: _buildLevelOption(
                        level: CompressionLevel.low,
                        title: 'Low Compression',
                        subtitle: 'Best visual quality, moderate reduction (~25%)',
                        icon: Icons.high_quality,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLevelOption(
                        level: CompressionLevel.medium,
                        title: 'Medium (Recommended)',
                        subtitle: 'Optimal balance of size & readability (~50%)',
                        icon: Icons.auto_awesome,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLevelOption(
                        level: CompressionLevel.high,
                        title: 'High Compression',
                        subtitle: 'Smallest file size, maximum reduction (~70%)',
                        icon: Icons.speed,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Live Results Display (Before vs After)
                if (_result != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('Before Compression', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  _result!.originalSizeFormatted,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_forward, size: 28, color: Colors.green),
                            Column(
                              children: [
                                const Text('After Compression', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  _result!.compressedSizeFormatted,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Estimated Reduction: ${_result!.reductionPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save_alt),
                          label: const Text('Save Compressed PDF'),
                          onPressed: _saveCompressedPdf,
                        ),
                      ],
                    ),
                  ),

                if (_isProcessing) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(value: _progress > 0 ? _progress : null),
                  const SizedBox(height: 8),
                  Text('Compressing document: ${(_progress * 100).toInt()}%', textAlign: TextAlign.center),
                ],

                const SizedBox(height: 24),

                FilledButton.icon(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: const Icon(Icons.compress),
                  label: const Text('Compress Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: _isProcessing ? null : _handleCompress,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelOption({
    required CompressionLevel level,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _level == level;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _level = level),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.cardColor,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? theme.colorScheme.primary : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.65))),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPdf() async {
    final path = await FileService.pickPdfFile();
    if (path != null) {
      final size = FileService.getFileSize(path);
      setState(() {
        _selectedFilePath = path;
        _originalSizeBytes = size;
        _result = null;
      });
    }
  }

  Future<void> _handleCompress() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.05;
      _result = null;
    });

    final taskId = ref.read(queueProvider.notifier).enqueueTask(
      title: 'Compress ${FileService.getFileName(_selectedFilePath!)}',
      operationName: 'Compress',
    );
    ref.read(queueProvider.notifier).startProcessing(taskId);

    try {
      final bytes = await File(_selectedFilePath!).readAsBytes();
      final res = await PdfCompressorService.compressPdf(
        originalBytes: bytes,
        level: _level,
        customScale: _customScale,
        onProgress: (p) {
          setState(() => _progress = p);
          ref.read(queueProvider.notifier).updateProgress(taskId, p);
        },
      );

      setState(() => _result = res);
      ref.read(queueProvider.notifier).updateProgress(taskId, 1.0);
    } catch (e) {
      ref.read(queueProvider.notifier).failTask(taskId, error: e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Compression failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _progress = 0.0;
        });
      }
    }
  }

  Future<void> _saveCompressedPdf() async {
    if (_result == null || _selectedFilePath == null) return;

    final base = FileService.getFileName(_selectedFilePath!);
    final savePath = await FileService.savePdfFile(
      fileName: '${base.replaceAll('.pdf', '')}_compressed.pdf',
      bytes: _result!.compressedBytes,
      dialogTitle: 'Save Compressed PDF',
    );

    if (savePath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compressed PDF saved to $savePath'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => ref.read(documentProvider.notifier).openFile(savePath),
          ),
        ),
      );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
