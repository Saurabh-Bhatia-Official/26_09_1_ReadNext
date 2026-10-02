import 'package:flutter/material.dart';
import 'batch_tool_view.dart';
import 'compare_tool_view.dart';
import 'compress_tool_view.dart';
import 'converter_tool_view.dart';
import 'merge_tool_view.dart';
import 'metadata_tool_view.dart';
import 'ocr_tool_view.dart';
import 'page_manager_view.dart';
import 'security_tool_view.dart';
import 'split_tool_view.dart';
import 'watermark_tool_view.dart';

class ToolItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String category;
  final void Function(BuildContext context, {void Function(int tabIndex)? onNavigateTab}) onOpen;

  const ToolItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.onOpen,
  });
}

class ToolsCatalog {
  static const List<String> categories = [
    'All',
    'Organize',
    'Optimize',
    'Convert',
    'Edit & Security',
    'OCR (Text)',
    'Batch',
  ];

  static final List<ToolItem> allTools = [
    // Organize
    ToolItem(
      id: 'merge',
      title: 'Merge PDF',
      description: 'Combine multiple PDF documents into a single organized file in custom order.',
      icon: Icons.call_merge,
      color: const Color(0xFF1E88E5),
      category: 'Organize',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MergeToolView())),
    ),
    ToolItem(
      id: 'split',
      title: 'Split PDF',
      description: 'Extract pages, split by custom range, equal intervals, or page numbers.',
      icon: Icons.call_split,
      color: const Color(0xFF00897B),
      category: 'Organize',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SplitToolView())),
    ),
    ToolItem(
      id: 'page_manager',
      title: 'Page Manager',
      description: 'Thumbnail grid to drag-reorder, rotate, duplicate, reverse, or delete pages.',
      icon: Icons.auto_stories,
      color: const Color(0xFF3949AB),
      category: 'Organize',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PageManagerView())),
    ),
    ToolItem(
      id: 'rotate',
      title: 'Rotate Pages',
      description: 'Rotate all or selected PDF pages 90°, 180°, or 270° degrees permanently.',
      icon: Icons.rotate_right,
      color: const Color(0xFF00ACC1),
      category: 'Organize',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PageManagerView())),
    ),
    ToolItem(
      id: 'extract',
      title: 'Extract Pages',
      description: 'Select and save individual pages into a separate standalone PDF document.',
      icon: Icons.file_copy_outlined,
      color: const Color(0xFF546E7A),
      category: 'Organize',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SplitToolView())),
    ),

    // Optimize
    ToolItem(
      id: 'compress',
      title: 'Compress PDF',
      description: 'Reduce PDF file size with Low, Medium, High, or Custom compression presets.',
      icon: Icons.compress,
      color: const Color(0xFF00897B),
      category: 'Optimize',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompressToolView())),
    ),
    ToolItem(
      id: 'repair',
      title: 'Repair PDF',
      description: 'Rebuild corrupted xref tables and stream dictionaries into valid clean files.',
      icon: Icons.build_circle_outlined,
      color: const Color(0xFFE64A19),
      category: 'Optimize',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompressToolView())),
    ),

    // Convert
    ToolItem(
      id: 'pdf_to_images',
      title: 'PDF to Images',
      description: 'Convert all or selected pages into PNG, JPG, or WEBP high-resolution graphics.',
      icon: Icons.photo_library_outlined,
      color: const Color(0xFF8E24AA),
      category: 'Convert',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConverterToolView(initialTabIndex: 0))),
    ),
    ToolItem(
      id: 'images_to_pdf',
      title: 'Images to PDF',
      description: 'Combine photos & scanned graphics into a unified PDF with customizable margins.',
      icon: Icons.picture_as_pdf_outlined,
      color: const Color(0xFF3F51B5),
      category: 'Convert',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConverterToolView(initialTabIndex: 1))),
    ),
    ToolItem(
      id: 'pdf_to_word',
      title: 'PDF to Word',
      description: 'Convert PDF text and paragraph flow into editable Microsoft Word (.docx) documents.',
      icon: Icons.article_outlined,
      color: const Color(0xFF1976D2),
      category: 'Convert',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConverterToolView(initialTabIndex: 2))),
    ),
    ToolItem(
      id: 'pdf_to_excel',
      title: 'PDF to Excel',
      description: 'Extract data and tabular layouts into editable Microsoft Excel (.xlsx) spreadsheets.',
      icon: Icons.table_chart_outlined,
      color: const Color(0xFF2E7D32),
      category: 'Convert',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConverterToolView(initialTabIndex: 2))),
    ),
    ToolItem(
      id: 'pdf_to_ppt',
      title: 'PDF to PPT',
      description: 'Convert PDF presentation pages into editable PowerPoint (.pptx) presentation slides.',
      icon: Icons.slideshow_outlined,
      color: const Color(0xFFE65100),
      category: 'Convert',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConverterToolView(initialTabIndex: 2))),
    ),

    // Edit & Security
    ToolItem(
      id: 'annotate',
      title: 'Annotate & Draw',
      description: 'Add highlights, sticky notes, shapes, ink drawings, and approved stamps.',
      icon: Icons.edit_note,
      color: const Color(0xFFF57C00),
      category: 'Edit & Security',
      onOpen: (context, {onNavigateTab}) => onNavigateTab?.call(2), // Switch to Viewer
    ),
    ToolItem(
      id: 'watermark',
      title: 'Watermark PDF',
      description: 'Add customizable text or logo image watermarks with opacity and angle controls.',
      icon: Icons.branding_watermark_outlined,
      color: const Color(0xFF7B1FA2),
      category: 'Edit & Security',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WatermarkToolView())),
    ),
    ToolItem(
      id: 'security',
      title: 'Password & Security',
      description: 'Encrypt with passwords, restrict printing, copying, or modifying; unlock authorized PDFs.',
      icon: Icons.lock_outline,
      color: const Color(0xFFD32F2F),
      category: 'Edit & Security',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecurityToolView())),
    ),
    ToolItem(
      id: 'metadata',
      title: 'Document Properties',
      description: 'View and edit internal Title, Author, Subject, Keywords, and Creator fields.',
      icon: Icons.info_outline,
      color: const Color(0xFF455A64),
      category: 'Edit & Security',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MetadataToolView())),
    ),
    ToolItem(
      id: 'compare',
      title: 'Compare PDFs',
      description: 'Side-by-side visual difference and text additions/removals detection.',
      icon: Icons.compare_arrows,
      color: const Color(0xFF303F9F),
      category: 'Edit & Security',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompareToolView())),
    ),

    // OCR
    ToolItem(
      id: 'ocr',
      title: 'OCR Extraction',
      description: 'Recognize and copy text from scanned PDFs & images (English, Hindi, Marathi).',
      icon: Icons.document_scanner,
      color: const Color(0xFFE64A19),
      category: 'OCR (Text)',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OcrToolView())),
    ),
    ToolItem(
      id: 'searchable_pdf',
      title: 'Searchable PDF',
      description: 'Overlay an invisible searchable text layer above scanned images for Ctrl+F indexing.',
      icon: Icons.search,
      color: const Color(0xFF1976D2),
      category: 'OCR (Text)',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OcrToolView())),
    ),

    // Batch
    ToolItem(
      id: 'batch',
      title: 'Batch Queue',
      description: 'Process dozens of files simultaneously: Batch Compress, Convert, Watermark, OCR.',
      icon: Icons.dynamic_feed,
      color: const Color(0xFF00796B),
      category: 'Batch',
      onOpen: (context, {onNavigateTab}) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BatchToolView())),
    ),
  ];
}
