import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../services/file_service.dart';
import '../../../services/pdf/pdf_organizer_service.dart';
import '../../../state/queue_provider.dart';

class SplitToolView extends ConsumerStatefulWidget {
  const SplitToolView({super.key});

  @override
  ConsumerState<SplitToolView> createState() => _SplitToolViewState();
}

class _SplitToolViewState extends ConsumerState<SplitToolView> {
  String? _selectedFilePath;
  int _pageCount = 0;
  SplitMode _splitMode = SplitMode.everyPage;
  final TextEditingController _rangeController = TextEditingController(text: '1-2, 3-4');
  final TextEditingController _groupSizeController = TextEditingController(text: '2');
  final TextEditingController _extractPagesController = TextEditingController(text: '1, 3');

  bool _isProcessing = false;
  double _progress = 0.0;
  String? _statusMessage;

  @override
  void dispose() {
    _rangeController.dispose();
    _groupSizeController.dispose();
    _extractPagesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split PDF File'),
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
              // File Selection Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.call_split, color: theme.colorScheme.primary, size: 28),
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
                                  ? '$_pageCount page(s) • ${_selectedFilePath!}'
                                  : 'Choose a PDF file to split into separate documents',
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
                Text('Choose Split Method', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // Mode Options
                RadioListTile<SplitMode>(
                  title: const Text('Split every page into a single PDF'),
                  subtitle: Text('Outputs $_pageCount separate single-page documents'),
                  value: SplitMode.everyPage,
                  groupValue: _splitMode,
                  onChanged: (val) => setState(() => _splitMode = val!),
                ),

                RadioListTile<SplitMode>(
                  title: const Text('Split by page ranges'),
                  subtitle: const Text('Example: 1-5, 6-10, 11-15'),
                  value: SplitMode.pageRanges,
                  groupValue: _splitMode,
                  onChanged: (val) => setState(() => _splitMode = val!),
                ),
                if (_splitMode == SplitMode.pageRanges)
                  Padding(
                    padding: const EdgeInsets.only(left: 36, right: 16, bottom: 12),
                    child: TextField(
                      controller: _rangeController,
                      decoration: const InputDecoration(
                        labelText: 'Page Ranges',
                        hintText: 'e.g. 1-2, 3-5, 6-8',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                RadioListTile<SplitMode>(
                  title: const Text('Split into equal groups'),
                  subtitle: const Text('Fixed number of pages per file'),
                  value: SplitMode.equalGroups,
                  groupValue: _splitMode,
                  onChanged: (val) => setState(() => _splitMode = val!),
                ),
                if (_splitMode == SplitMode.equalGroups)
                  Padding(
                    padding: const EdgeInsets.only(left: 36, right: 16, bottom: 12),
                    child: TextField(
                      controller: _groupSizeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pages per group',
                        hintText: 'e.g. 2',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                RadioListTile<SplitMode>(
                  title: const Text('Extract selected individual pages'),
                  subtitle: const Text('Example: 1, 3, 5, 7'),
                  value: SplitMode.extractPages,
                  groupValue: _splitMode,
                  onChanged: (val) => setState(() => _splitMode = val!),
                ),
                if (_splitMode == SplitMode.extractPages)
                  Padding(
                    padding: const EdgeInsets.only(left: 36, right: 16, bottom: 12),
                    child: TextField(
                      controller: _extractPagesController,
                      decoration: const InputDecoration(
                        labelText: 'Pages to extract (comma separated)',
                        hintText: 'e.g. 1, 3, 5',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                if (_isProcessing) ...[
                  LinearProgressIndicator(value: _progress > 0 ? _progress : null),
                  const SizedBox(height: 8),
                  Text(_statusMessage ?? 'Splitting PDF...', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                ],

                FilledButton.icon(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: const Icon(Icons.call_split),
                  label: const Text('Split Document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: _isProcessing ? null : _handleSplit,
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
      final file = File(path);
      final bytes = await file.readAsBytes();
      // Inspect page count
      int count = 1;
      try {
        final raw = String.fromCharCodes(bytes);
        final matches = RegExp(r'/Type\s*/Page\b').allMatches(raw);
        if (matches.isNotEmpty) count = matches.length;
      } catch (_) {}

      setState(() {
        _selectedFilePath = path;
        _pageCount = count;
      });
    }
  }

  Future<void> _handleSplit() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.05;
      _statusMessage = 'Preparing split...';
    });

    final taskId = ref.read(queueProvider.notifier).enqueueTask(
      title: 'Split ${FileService.getFileName(_selectedFilePath!)}',
      operationName: 'Split',
    );
    ref.read(queueProvider.notifier).startProcessing(taskId);

    try {
      final file = File(_selectedFilePath!);
      final bytes = await file.readAsBytes();

      List<int>? extractList;
      if (_splitMode == SplitMode.extractPages) {
        extractList = _extractPagesController.text
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .toList();
      }

      final results = await PdfOrganizerService.splitPdf(
        bytes: bytes,
        mode: _splitMode,
        pageRanges: _rangeController.text,
        groupSize: int.tryParse(_groupSizeController.text) ?? 2,
        pagesToExtract: extractList,
        onProgress: (p) {
          setState(() {
            _progress = p;
            _statusMessage = 'Splitting parts: ${(p * 100).toInt()}%';
          });
          ref.read(queueProvider.notifier).updateProgress(taskId, p);
        },
      );

      // Save split parts into documents output folder
      final appDocDir = await getApplicationDocumentsDirectory();
      final outFolder = Directory(p.join(appDocDir.path, 'ReadNext_Split_${DateTime.now().millisecondsSinceEpoch}'));
      await outFolder.create(recursive: true);

      for (final item in results) {
        final filePath = p.join(outFolder.path, item.title);
        await File(filePath).writeAsBytes(item.bytes);
      }

      ref.read(queueProvider.notifier).completeTask(
        taskId,
        outputPath: outFolder.path,
        successMessage: 'Successfully split into ${results.length} files.',
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Split Completed!'),
            content: Text('${results.length} files saved to:\n${outFolder.path}'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      ref.read(queueProvider.notifier).failTask(taskId, error: e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Split failed: $e')));
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
