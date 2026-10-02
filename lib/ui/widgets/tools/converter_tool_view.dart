import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../services/file_service.dart';
import '../../../services/pdf/pdf_converter_service.dart';
import '../../../state/document_provider.dart';
import '../../../state/queue_provider.dart';

class ConverterToolView extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const ConverterToolView({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<ConverterToolView> createState() => _ConverterToolViewState();
}

class _ConverterToolViewState extends ConsumerState<ConverterToolView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // State for PDF to Image
  String? _pdfToImgPath;
  String _imgFormat = 'png';
  bool _isConvertingPdfToImg = false;

  // State for Image to PDF
  final List<String> _selectedImages = [];
  final PdfPagePreset _imgPagePreset = PdfPagePreset.a4;
  final PdfPageOrientation _imgOrientation = PdfPageOrientation.auto;
  bool _isConvertingImgToPdf = false;

  // State for PDF to Office
  String? _officePdfPath;
  String _officeTarget = 'docx'; // 'docx', 'xlsx', 'pptx'
  bool _isConvertingOffice = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final docState = ref.read(documentProvider);
      if (docState.currentPath != null && File(docState.currentPath!).existsSync()) {
        if (mounted) {
          setState(() {
            _officePdfPath ??= docState.currentPath;
            _pdfToImgPath ??= docState.currentPath;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Convert Documents & Images'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'PDF to Images', icon: Icon(Icons.image_outlined)),
            Tab(text: 'Images to PDF', icon: Icon(Icons.picture_as_pdf_outlined)),
            Tab(text: 'PDF to Office', icon: Icon(Icons.description_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPdfToImagesTab(theme),
          _buildImagesToPdfTab(theme),
          _buildPdfToOfficeTab(theme),
        ],
      ),
    );
  }

  // --- TAB 1: PDF to Images (Free) ---
  Widget _buildPdfToImagesTab(ThemeData theme) {
    return SingleChildScrollView(
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
                        color: Colors.deepPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.photo_library, color: Colors.deepPurple, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pdfToImgPath != null ? FileService.getFileName(_pdfToImgPath!) : 'No PDF selected',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _pdfToImgPath != null ? _pdfToImgPath! : 'Extract each PDF page as a high-resolution image',
                            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.folder_open),
                      label: Text(_pdfToImgPath == null ? 'Select PDF' : 'Change'),
                      onPressed: _isConvertingPdfToImg
                          ? null
                          : () async {
                              final p = await FileService.pickPdfFile();
                              if (p != null) setState(() => _pdfToImgPath = p);
                            },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_pdfToImgPath != null) ...[
              Text('Image Output Format', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: ['png', 'jpg', 'webp'].map((fmt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: ChoiceChip(
                      label: Text(fmt.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      selected: _imgFormat == fmt,
                      onSelected: (val) => setState(() => _imgFormat = fmt),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              if (_isConvertingPdfToImg) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                const Text('Extracting pages to images...', textAlign: TextAlign.center),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                icon: const Icon(Icons.photo_filter),
                label: const Text('Convert & Save Images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _isConvertingPdfToImg ? null : _convertPdfToImages,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- TAB 2: Images to PDF (Free) ---
  Widget _buildImagesToPdfTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Images (JPG, PNG, WEBP)'),
                onPressed: _isConvertingImgToPdf ? null : _pickImages,
              ),
              const SizedBox(width: 12),
              if (_selectedImages.isNotEmpty)
                OutlinedButton.icon(
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All'),
                  onPressed: () => setState(() => _selectedImages.clear()),
                ),
              const Spacer(),
              Text('${_selectedImages.length} image(s) selected', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedImages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.collections, size: 56, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text('No images added yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Add images to arrange and compile them into a PDF document'),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: _selectedImages.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) newIndex -= 1;
                        final img = _selectedImages.removeAt(oldIndex);
                        _selectedImages.insert(newIndex, img);
                      });
                    },
                    itemBuilder: (context, index) {
                      final path = _selectedImages[index];
                      final name = p.basename(path);
                      return Card(
                        key: ValueKey(path),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(name),
                          subtitle: Text(path, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => setState(() => _selectedImages.removeAt(index)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generate PDF from Images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: (_selectedImages.isNotEmpty && !_isConvertingImgToPdf) ? _convertImagesToPdf : null,
          ),
        ],
      ),
    );
  }

  // --- TAB 3: PDF to Office (Word, Excel, PPT) ---
  Widget _buildPdfToOfficeTab(ThemeData theme) {
    return SingleChildScrollView(
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
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.document_scanner, color: Colors.blue, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _officePdfPath != null ? FileService.getFileName(_officePdfPath!) : 'No PDF selected',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _officePdfPath != null ? _officePdfPath! : 'Select a PDF document to convert to editable Office files',
                            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.folder_open),
                      label: Text(_officePdfPath == null ? 'Select PDF' : 'Change'),
                      onPressed: () async {
                        final p = await FileService.pickPdfFile();
                        if (p != null) setState(() => _officePdfPath = p);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text('Select Office Target Format', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildOfficeFormatCard(
                    id: 'docx',
                    title: 'Word Document',
                    ext: '.docx',
                    subtitle: 'Editable paragraphs, headings & text flow',
                    icon: Icons.article,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOfficeFormatCard(
                    id: 'xlsx',
                    title: 'Excel Spreadsheet',
                    ext: '.xlsx',
                    subtitle: 'Financial tables, reports & grid data',
                    icon: Icons.table_chart,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOfficeFormatCard(
                    id: 'pptx',
                    title: 'PowerPoint Slide',
                    ext: '.pptx',
                    subtitle: 'Presentation slides with layout graphics',
                    icon: Icons.slideshow,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_isConvertingOffice) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text('Generating editable ${_officeTarget.toUpperCase()} document...', textAlign: TextAlign.center),
              const SizedBox(height: 16),
            ],

            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              icon: const Icon(Icons.sync_alt),
              label: Text('Convert to ${_officeTarget.toUpperCase()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: (_officePdfPath != null && !_isConvertingOffice) ? _handleOfficeConvert : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficeFormatCard({
    required String id,
    required String title,
    required String ext,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _officeTarget == id;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _officeTarget = id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : theme.dividerColor,
            width: isSelected ? 2.5 : 1,
          ),
          color: isSelected ? color.withValues(alpha: 0.08) : theme.cardColor,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(ext, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Future<void> _convertPdfToImages() async {
    if (_pdfToImgPath == null) return;
    setState(() => _isConvertingPdfToImg = true);

    try {
      final bytes = await File(_pdfToImgPath!).readAsBytes();
      final images = await PdfConverterService.pdfToImages(pdfBytes: bytes, format: _imgFormat);

      final appDocDir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(appDocDir.path, 'ReadNext_Images_${DateTime.now().millisecondsSinceEpoch}'));
      await folder.create(recursive: true);

      for (final img in images) {
        await File(p.join(folder.path, img.fileName)).writeAsBytes(img.bytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extracted ${images.length} images to ${folder.path}')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isConvertingPdfToImg = false);
    }
  }

  Future<void> _pickImages() async {
    final paths = await FileService.pickMultipleImageFiles();
    setState(() {
      for (final p in paths) {
        if (!_selectedImages.contains(p)) _selectedImages.add(p);
      }
    });
  }

  Future<void> _convertImagesToPdf() async {
    if (_selectedImages.isEmpty) return;
    setState(() => _isConvertingImgToPdf = true);

    try {
      final List<Uint8List> byteList = [];
      for (final path in _selectedImages) {
        byteList.add(await File(path).readAsBytes());
      }

      final pdfBytes = await PdfConverterService.imagesToPdf(
        imageBytesList: byteList,
        pagePreset: _imgPagePreset,
        orientation: _imgOrientation,
      );

      final savePath = await FileService.savePdfFile(
        fileName: 'Photos_Combined_${DateTime.now().millisecondsSinceEpoch}.pdf',
        bytes: pdfBytes,
        dialogTitle: 'Save Generated PDF',
      );

      if (savePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF saved to $savePath')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isConvertingImgToPdf = false);
    }
  }

  Future<void> _handleOfficeConvert() async {
    if (_officePdfPath == null) return;

    setState(() => _isConvertingOffice = true);

    final taskId = ref.read(queueProvider.notifier).enqueueTask(
      title: 'Convert to ${_officeTarget.toUpperCase()}',
      operationName: 'Convert',
    );
    ref.read(queueProvider.notifier).startProcessing(taskId);

    try {
      final bytes = await File(_officePdfPath!).readAsBytes();
      final baseName = p.basenameWithoutExtension(_officePdfPath!);

      Uint8List outBytes;
      String extension;
      String mime;

      if (_officeTarget == 'xlsx') {
        outBytes = await PdfConverterService.pdfToExcelXlsx(pdfBytes: bytes);
        extension = 'xlsx';
        mime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      } else if (_officeTarget == 'pptx') {
        outBytes = await PdfConverterService.pdfToPowerPointPptx(pdfBytes: bytes);
        extension = 'pptx';
        mime = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      } else {
        outBytes = await PdfConverterService.pdfToWordDocx(pdfBytes: bytes);
        extension = 'docx';
        mime = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      }

      final savePath = await FileService.saveExportFile(
        fileName: '$baseName.$extension',
        bytes: outBytes,
        extension: extension,
        mimeType: mime,
        dialogTitle: 'Save ${_officeTarget.toUpperCase()} Document',
      );

      if (savePath != null) {
        ref.read(queueProvider.notifier).completeTask(taskId, outputPath: savePath, successMessage: 'Converted to $extension successfully.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported $extension document to $savePath'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () => FileService.openFileOrFolder(savePath),
              ),
            ),
          );
        }
      } else {
        ref.read(queueProvider.notifier).cancelTask(taskId);
      }
    } catch (e) {
      ref.read(queueProvider.notifier).failTask(taskId, error: e.toString());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Conversion failed: $e')));
    } finally {
      if (mounted) setState(() => _isConvertingOffice = false);
    }
  }
}
