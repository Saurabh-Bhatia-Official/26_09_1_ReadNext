import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/file_service.dart';
import '../../../services/pdf/pdf_comparison_service.dart';

class CompareToolView extends ConsumerStatefulWidget {
  const CompareToolView({super.key});

  @override
  ConsumerState<CompareToolView> createState() => _CompareToolViewState();
}

class _CompareToolViewState extends ConsumerState<CompareToolView> {
  String? _pathA;
  String? _pathB;
  bool _isComparing = false;
  ComparisonResult? _comparisonResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Document Comparison'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Document A and Document B Selectors Side-by-Side
            Row(
              children: [
                Expanded(
                  child: _buildDocSelector(
                    label: 'Document A (Original)',
                    path: _pathA,
                    color: Colors.blue,
                    onPick: (p) => setState(() => _pathA = p),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDocSelector(
                    label: 'Document B (Modified)',
                    path: _pathB,
                    color: Colors.indigo,
                    onPick: (p) => setState(() => _pathB = p),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Compare Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: (_pathA != null && _pathB != null && !_isComparing) ? _runComparison : null,
            ),

            if (_isComparing) ...[
              const SizedBox(height: 24),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Analyzing textual & layout differences...', textAlign: TextAlign.center),
            ],

            // Comparison Summary & Diffs
            if (_comparisonResult != null) ...[
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _comparisonResult!.hasDifferences ? Colors.amber.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _comparisonResult!.hasDifferences ? Colors.amber : Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(
                      _comparisonResult!.hasDifferences ? Icons.difference : Icons.check_circle,
                      color: _comparisonResult!.hasDifferences ? Colors.amber.shade800 : Colors.green,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Comparison Result', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(_comparisonResult!.summary, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text('Page-by-Page Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              ..._comparisonResult!.pageDiffs.map((diff) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: diff.diffType == ComparisonDiffType.identical
                                  ? Colors.green
                                  : diff.diffType == ComparisonDiffType.modified
                                      ? Colors.amber.shade700
                                      : Colors.blue,
                              child: Text('${diff.pageNumber}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                            const SizedBox(width: 10),
                            Text('Page ${diff.pageNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: diff.diffType == ComparisonDiffType.identical
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : diff.diffType == ComparisonDiffType.modified
                                        ? Colors.amber.withValues(alpha: 0.15)
                                        : Colors.blue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                diff.diffType.name.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: diff.diffType == ComparisonDiffType.identical
                                      ? Colors.green
                                      : diff.diffType == ComparisonDiffType.modified
                                          ? Colors.amber.shade900
                                          : Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (diff.addedWords.isNotEmpty || diff.removedWords.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          if (diff.addedWords.isNotEmpty)
                            Text(
                              '+ Added in Doc B: ${diff.addedWords.take(15).join(', ')}',
                              style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          if (diff.removedWords.isNotEmpty)
                            Text(
                              '- Removed from Doc A: ${diff.removedWords.take(15).join(', ')}',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                        ],
                        const SizedBox(height: 12),
                        // Side-by-side Page Preview
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(6),
                                  color: Colors.white,
                                ),
                                child: diff.pageAImage != null
                                    ? Image.memory(diff.pageAImage!, fit: BoxFit.contain)
                                    : const Center(child: Text('(Page not present in Doc A)', style: TextStyle(fontSize: 11, color: Colors.grey))),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(6),
                                  color: Colors.white,
                                ),
                                child: diff.pageBImage != null
                                    ? Image.memory(diff.pageBImage!, fit: BoxFit.contain)
                                    : const Center(child: Text('(Page not present in Doc B)', style: TextStyle(fontSize: 11, color: Colors.grey))),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildDocSelector({
    required String label,
    required String? path,
    required Color color,
    required void Function(String?) onPick,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              path != null ? FileService.getFileName(path) : 'No file chosen',
              style: TextStyle(fontWeight: FontWeight.w600, color: path != null ? color : Colors.grey),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: Text(path == null ? 'Select PDF' : 'Change'),
              onPressed: () async {
                final p = await FileService.pickPdfFile();
                if (p != null) onPick(p);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runComparison() async {
    if (_pathA == null || _pathB == null) return;

    setState(() {
      _isComparing = true;
      _comparisonResult = null;
    });

    try {
      final bytesA = await File(_pathA!).readAsBytes();
      final bytesB = await File(_pathB!).readAsBytes();

      final res = await PdfComparisonService.compareDocuments(bytesA: bytesA, bytesB: bytesB);
      setState(() => _comparisonResult = res);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Comparison failed: $e')));
    } finally {
      if (mounted) setState(() => _isComparing = false);
    }
  }
}
