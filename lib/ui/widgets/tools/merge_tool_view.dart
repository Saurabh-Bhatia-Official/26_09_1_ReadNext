import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/file_service.dart';
import '../../../services/pdf/pdf_organizer_service.dart';
import '../../../state/document_provider.dart';
import '../../../state/queue_provider.dart';

class MergeToolView extends ConsumerStatefulWidget {
  const MergeToolView({super.key});

  @override
  ConsumerState<MergeToolView> createState() => _MergeToolViewState();
}

class _MergeToolViewState extends ConsumerState<MergeToolView> {
  final List<String> _selectedFiles = [];
  bool _isProcessing = false;
  double _progress = 0.0;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merge PDF Files'),
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
                  icon: const Icon(Icons.add),
                  label: const Text('Add PDF Documents'),
                  onPressed: _isProcessing ? null : _pickFiles,
                ),
                const SizedBox(width: 12),
                if (_selectedFiles.isNotEmpty)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All'),
                    onPressed: _isProcessing ? null : () => setState(() => _selectedFiles.clear()),
                  ),
                const Spacer(),
                Text(
                  '${_selectedFiles.length} file(s) selected',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Files list with reordering
            Expanded(
              child: _selectedFiles.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                        color: theme.cardColor,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call_merge, size: 56, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text('No PDF files added yet.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('Click "Add PDF Documents" to select multiple files to combine.',
                                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: _selectedFiles.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) newIndex -= 1;
                          final item = _selectedFiles.removeAt(oldIndex);
                          _selectedFiles.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final path = _selectedFiles[index];
                        final name = FileService.getFileName(path);
                        final size = FileService.getFileSize(path);
                        final sizeKb = (size / 1024).toStringAsFixed(1);

                        return Card(
                          key: ValueKey(path),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('$sizeKb KB • $path', maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_upward, size: 20),
                                  tooltip: 'Move Up',
                                  onPressed: index > 0
                                      ? () {
                                          setState(() {
                                            final item = _selectedFiles.removeAt(index);
                                            _selectedFiles.insert(index - 1, item);
                                          });
                                        }
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_downward, size: 20),
                                  tooltip: 'Move Down',
                                  onPressed: index < _selectedFiles.length - 1
                                      ? () {
                                          setState(() {
                                            final item = _selectedFiles.removeAt(index);
                                            _selectedFiles.insert(index + 1, item);
                                          });
                                        }
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Remove',
                                  onPressed: () => setState(() => _selectedFiles.removeAt(index)),
                                ),
                                const ReorderableDragStartListener(
                                  index: 0,
                                  child: Icon(Icons.drag_handle),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            if (_isProcessing) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress > 0 ? _progress : null),
              const SizedBox(height: 8),
              Text(_statusMessage ?? 'Merging documents...', textAlign: TextAlign.center),
            ],

            const SizedBox(height: 16),

            // Merge Action Button
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              icon: const Icon(Icons.merge_type),
              label: const Text('Merge into Combined PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: (_selectedFiles.length >= 2 && !_isProcessing) ? _handleMerge : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    final paths = await FileService.pickMultiplePdfFiles();
    setState(() {
      for (final p in paths) {
        if (!_selectedFiles.contains(p)) _selectedFiles.add(p);
      }
    });
  }

  Future<void> _handleMerge() async {
    setState(() {
      _isProcessing = true;
      _progress = 0.05;
      _statusMessage = 'Reading files...';
    });

    final taskId = ref.read(queueProvider.notifier).enqueueTask(
      title: 'Merge ${_selectedFiles.length} PDFs',
      operationName: 'Merge',
    );
    ref.read(queueProvider.notifier).startProcessing(taskId);

    try {
      final mergedBytes = await PdfOrganizerService.mergePdfFiles(
        filePaths: _selectedFiles,
        onProgress: (p) {
          setState(() {
            _progress = p;
            _statusMessage = 'Merging pages: ${(p * 100).toInt()}%';
          });
          ref.read(queueProvider.notifier).updateProgress(taskId, p);
        },
      );

      final savePath = await FileService.savePdfFile(
        fileName: 'Combined_${DateTime.now().millisecondsSinceEpoch}.pdf',
        bytes: mergedBytes,
        dialogTitle: 'Save Merged PDF',
      );

      if (savePath != null) {
        ref.read(queueProvider.notifier).completeTask(taskId, outputPath: savePath, successMessage: 'PDFs merged successfully.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Merged PDF saved to $savePath'),
              action: SnackBarAction(
                label: 'Open Document',
                onPressed: () => ref.read(documentProvider.notifier).openFile(savePath),
              ),
            ),
          );
        }
      } else {
        ref.read(queueProvider.notifier).cancelTask(taskId);
      }
    } catch (e) {
      ref.read(queueProvider.notifier).failTask(taskId, error: e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Merge failed: $e')));
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
}
