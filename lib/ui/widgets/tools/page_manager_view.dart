import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart' as pfx;
import '../../../services/file_service.dart';
import '../../../services/pdf/pdf_organizer_service.dart';
import '../../../state/document_provider.dart';

class PageThumbnailItem {
  final int originalPageNumber;
  int rotationDegrees;
  Uint8List? thumbnailBytes;

  PageThumbnailItem({
    required this.originalPageNumber,
    this.rotationDegrees = 0,
    this.thumbnailBytes,
  });
}

class PageManagerView extends ConsumerStatefulWidget {
  final String? initialFilePath;
  const PageManagerView({super.key, this.initialFilePath});

  @override
  ConsumerState<PageManagerView> createState() => _PageManagerViewState();
}

class _PageManagerViewState extends ConsumerState<PageManagerView> {
  String? _filePath;
  Uint8List? _originalBytes;
  List<PageThumbnailItem> _pages = [];
  bool _isLoading = false;
  bool _isSaving = false;
  int? _selectedPageIndex;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilePath != null) {
      _loadFile(widget.initialFilePath!);
    } else {
      final docState = ref.read(documentProvider);
      if (docState.currentPath != null) {
        _loadFile(docState.currentPath!);
      }
    }
  }

  Future<void> _loadFile(String path) async {
    setState(() {
      _filePath = path;
      _isLoading = true;
      _pages = [];
      _selectedPageIndex = null;
    });

    try {
      final bytes = await File(path).readAsBytes();
      _originalBytes = bytes;
      final doc = await pfx.PdfDocument.openData(bytes);
      final count = doc.pagesCount;

      final List<PageThumbnailItem> items = [];
      for (int i = 1; i <= count; i++) {
        final page = await doc.getPage(i);
        final rendered = await page.render(width: 140, height: 190, format: pfx.PdfPageImageFormat.png);
        await page.close();

        items.add(PageThumbnailItem(
          originalPageNumber: i,
          thumbnailBytes: rendered?.bytes,
        ));
      }
      await doc.close();

      if (mounted) {
        setState(() {
          _pages = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load pages: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_filePath != null ? 'Page Manager - ${FileService.getFileName(_filePath!)}' : 'Page Manager'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Open Another PDF',
            onPressed: _pickAnotherPdf,
          ),
          if (_pages.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.swap_vert),
              tooltip: 'Reverse Page Order',
              onPressed: _reversePages,
            ),
            IconButton(
              icon: const Icon(Icons.rotate_right),
              tooltip: 'Rotate Selected (90°)',
              onPressed: _selectedPageIndex != null ? _rotateSelected : null,
            ),
            IconButton(
              icon: const Icon(Icons.control_point_duplicate),
              tooltip: 'Duplicate Selected',
              onPressed: _selectedPageIndex != null ? _duplicateSelected : null,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Delete Selected',
              onPressed: _selectedPageIndex != null ? _deleteSelected : null,
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save PDF'),
              onPressed: _isSaving ? null : _saveOrganizedPdf,
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Rendering page thumbnails...'),
                ],
              ),
            )
          : _pages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_stories, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text('No PDF loaded in Page Manager', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Open PDF to Manage Pages'),
                        onPressed: _pickAnotherPdf,
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'Drag thumbnails to rearrange pages. Select a page to rotate, duplicate, or delete.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ),
                      Expanded(
                        child: ReorderableListView.builder(
                          scrollDirection: Axis.vertical,
                          itemCount: _pages.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (oldIndex < newIndex) newIndex -= 1;
                              final item = _pages.removeAt(oldIndex);
                              _pages.insert(newIndex, item);
                              _selectedPageIndex = newIndex;
                            });
                          },
                          itemBuilder: (context, index) {
                            final page = _pages[index];
                            final isSelected = _selectedPageIndex == index;

                            return Card(
                              key: ValueKey(page),
                              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              elevation: isSelected ? 4 : 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => setState(() => _selectedPageIndex = index),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    children: [
                                      // Position Badge
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                        child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 16),

                                      // Thumbnail
                                      Container(
                                        width: 70,
                                        height: 95,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(6),
                                          color: Colors.white,
                                        ),
                                        child: page.thumbnailBytes != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(5),
                                                child: Image.memory(
                                                  page.thumbnailBytes!,
                                                  fit: BoxFit.contain,
                                                ),
                                              )
                                            : const Icon(Icons.picture_as_pdf, color: Colors.grey),
                                      ),

                                      const SizedBox(width: 20),

                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Page ${index + 1} (Original Page ${page.originalPageNumber})',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Rotation: ${page.rotationDegrees}°',
                                              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Actions
                                      IconButton(
                                        icon: const Icon(Icons.rotate_right, size: 20),
                                        tooltip: 'Rotate 90°',
                                        onPressed: () {
                                          setState(() {
                                            page.rotationDegrees = (page.rotationDegrees + 90) % 360;
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.control_point_duplicate, size: 20),
                                        tooltip: 'Duplicate',
                                        onPressed: () {
                                          setState(() {
                                            _pages.insert(index + 1, PageThumbnailItem(
                                              originalPageNumber: page.originalPageNumber,
                                              thumbnailBytes: page.thumbnailBytes,
                                              rotationDegrees: page.rotationDegrees,
                                            ));
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                        tooltip: 'Delete',
                                        onPressed: _pages.length > 1
                                            ? () {
                                                setState(() {
                                                  _pages.removeAt(index);
                                                  if (_selectedPageIndex == index) _selectedPageIndex = null;
                                                });
                                              }
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      const ReorderableDragStartListener(
                                        index: 0,
                                        child: Icon(Icons.drag_handle, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  void _rotateSelected() {
    if (_selectedPageIndex == null) return;
    setState(() {
      _pages[_selectedPageIndex!].rotationDegrees =
          (_pages[_selectedPageIndex!].rotationDegrees + 90) % 360;
    });
  }

  void _duplicateSelected() {
    if (_selectedPageIndex == null) return;
    final item = _pages[_selectedPageIndex!];
    setState(() {
      _pages.insert(
        _selectedPageIndex! + 1,
        PageThumbnailItem(
          originalPageNumber: item.originalPageNumber,
          thumbnailBytes: item.thumbnailBytes,
          rotationDegrees: item.rotationDegrees,
        ),
      );
    });
  }

  void _deleteSelected() {
    if (_selectedPageIndex == null || _pages.length <= 1) return;
    setState(() {
      _pages.removeAt(_selectedPageIndex!);
      _selectedPageIndex = null;
    });
  }

  void _reversePages() {
    setState(() {
      _pages = _pages.reversed.toList();
    });
  }

  Future<void> _pickAnotherPdf() async {
    final path = await FileService.pickPdfFile();
    if (path != null) {
      await _loadFile(path);
    }
  }

  Future<void> _saveOrganizedPdf() async {
    if (_originalBytes == null || _pages.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final pageOrder = _pages.map((p) => p.originalPageNumber).toList();
      final reorderedBytes = await PdfOrganizerService.reorderPages(
        bytes: _originalBytes!,
        newPageOrder: pageOrder,
      );

      final savePath = await FileService.savePdfFile(
        fileName: 'Organized_${DateTime.now().millisecondsSinceEpoch}.pdf',
        bytes: reorderedBytes,
        dialogTitle: 'Save Modified PDF',
      );

      if (savePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved organized PDF to $savePath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => ref.read(documentProvider.notifier).openFile(savePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
