import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/file_service.dart';
import '../../../services/pdf/pdf_watermark_service.dart';
import '../../../state/document_provider.dart';
import '../../../state/queue_provider.dart';

class WatermarkToolView extends ConsumerStatefulWidget {
  const WatermarkToolView({super.key});

  @override
  ConsumerState<WatermarkToolView> createState() => _WatermarkToolViewState();
}

class _WatermarkToolViewState extends ConsumerState<WatermarkToolView> {
  String? _selectedPdfPath;
  WatermarkType _type = WatermarkType.text;
  final TextEditingController _textController = TextEditingController(text: 'CONFIDENTIAL');
  double _opacity = 0.35;
  double _rotation = -45.0;
  double _fontSize = 44.0;
  WatermarkPosition _position = WatermarkPosition.center;
  String? _selectedImagePath;

  bool _isProcessing = false;
  double _progress = 0.0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watermark PDF'),
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

              // File Picker Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.branding_watermark, color: Colors.purple, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedPdfPath != null ? FileService.getFileName(_selectedPdfPath!) : 'No PDF selected',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedPdfPath != null ? _selectedPdfPath! : 'Choose a PDF to watermark with security stamps or logos',
                              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.folder_open),
                        label: Text(_selectedPdfPath == null ? 'Select PDF' : 'Change'),
                        onPressed: () async {
                          final p = await FileService.pickPdfFile();
                          if (p != null) setState(() => _selectedPdfPath = p);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Watermark Type Selector
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<WatermarkType>(
                      title: const Text('Text Watermark'),
                      value: WatermarkType.text,
                      groupValue: _type,
                      onChanged: (val) => setState(() => _type = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<WatermarkType>(
                      title: const Text('Image Logo Watermark'),
                      value: WatermarkType.image,
                      groupValue: _type,
                      onChanged: (val) => setState(() => _type = val!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (_type == WatermarkType.text) ...[
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: 'Watermark Text',
                    hintText: 'e.g. CONFIDENTIAL, DRAFT, DO NOT COPY',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Font Size: ${_fontSize.toInt()} px'),
                          Slider(
                            value: _fontSize,
                            min: 16,
                            max: 96,
                            onChanged: (v) => setState(() => _fontSize = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rotation: ${_rotation.toInt()}°'),
                          Slider(
                            value: _rotation,
                            min: -90,
                            max: 90,
                            onChanged: (v) => setState(() => _rotation = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.image),
                  label: Text(_selectedImagePath != null ? FileService.getFileName(_selectedImagePath!) : 'Upload Logo Image (PNG / JPG)'),
                  onPressed: () async {
                    final path = await FileService.pickSingleImageFile();
                    if (path != null) {
                      setState(() => _selectedImagePath = path);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Opacity: ${(_opacity * 100).toInt()}%'),
                  Slider(
                    value: _opacity,
                    min: 0.1,
                    max: 1.0,
                    onChanged: (v) => setState(() => _opacity = v),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<WatermarkPosition>(
                initialValue: _position,
                decoration: const InputDecoration(
                  labelText: 'Position on Page',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: WatermarkPosition.center, child: Text('Center')),
                  DropdownMenuItem(value: WatermarkPosition.topLeft, child: Text('Top Left')),
                  DropdownMenuItem(value: WatermarkPosition.topRight, child: Text('Top Right')),
                  DropdownMenuItem(value: WatermarkPosition.bottomLeft, child: Text('Bottom Left')),
                  DropdownMenuItem(value: WatermarkPosition.bottomRight, child: Text('Bottom Right')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _position = val);
                },
              ),

              const SizedBox(height: 24),

              if (_isProcessing) ...[
                LinearProgressIndicator(value: _progress > 0 ? _progress : null),
                const SizedBox(height: 8),
                Text('Applying watermark: ${(_progress * 100).toInt()}%', textAlign: TextAlign.center),
                const SizedBox(height: 16),
              ],

              FilledButton.icon(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                icon: const Icon(Icons.branding_watermark),
                label: const Text('Apply Watermark & Save PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: (_selectedPdfPath != null && !_isProcessing) ? _handleApplyWatermark : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleApplyWatermark() async {
    if (_selectedPdfPath == null) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.05;
    });

    final taskId = ref.read(queueProvider.notifier).enqueueTask(
      title: 'Watermark ${FileService.getFileName(_selectedPdfPath!)}',
      operationName: 'Watermark',
    );
    ref.read(queueProvider.notifier).startProcessing(taskId);

    try {
      final pdfBytes = await File(_selectedPdfPath!).readAsBytes();
      Uint8List? imageBytes;
      if (_type == WatermarkType.image && _selectedImagePath != null) {
        imageBytes = await File(_selectedImagePath!).readAsBytes();
      }

      final config = WatermarkConfig(
        type: _type,
        text: _textController.text.trim().isNotEmpty ? _textController.text.trim() : 'CONFIDENTIAL',
        fontSize: _fontSize,
        opacity: _opacity,
        rotationDegrees: _rotation,
        position: _position,
        imageBytes: imageBytes,
      );

      final watermarked = await PdfWatermarkService.applyWatermark(
        pdfBytes: pdfBytes,
        config: config,
        onProgress: (p) {
          setState(() => _progress = p);
          ref.read(queueProvider.notifier).updateProgress(taskId, p);
        },
      );

      final savePath = await FileService.savePdfFile(
        fileName: '${FileService.getFileName(_selectedPdfPath!).replaceAll('.pdf', '')}_watermarked.pdf',
        bytes: watermarked,
        dialogTitle: 'Save Watermarked PDF',
      );

      if (savePath != null && mounted) {
        ref.read(queueProvider.notifier).completeTask(taskId, outputPath: savePath, successMessage: 'Watermark applied successfully.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to $savePath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => ref.read(documentProvider.notifier).openFile(savePath),
            ),
          ),
        );
      } else {
        ref.read(queueProvider.notifier).cancelTask(taskId);
      }
    } catch (e) {
      ref.read(queueProvider.notifier).failTask(taskId, error: e.toString());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
