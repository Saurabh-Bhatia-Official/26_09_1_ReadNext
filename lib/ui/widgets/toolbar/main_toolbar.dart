import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/file_service.dart';
import '../../../services/pdf/pdf_export_service.dart';
import '../../../services/print_service.dart';
import '../../../state/annotation_provider.dart';
import '../../../state/document_provider.dart';
import '../../../state/navigation_provider.dart';
import '../../../state/search_provider.dart';
import '../../../state/settings_provider.dart';
import '../../../state/zoom_provider.dart';
import '../dialogs/document_properties_dialog.dart';
import '../dialogs/go_to_page_dialog.dart';
import '../dialogs/quick_tools_dialog.dart';

class MainToolbar extends ConsumerStatefulWidget {
  const MainToolbar({super.key});

  @override
  ConsumerState<MainToolbar> createState() => _MainToolbarState();
}

class _MainToolbarState extends ConsumerState<MainToolbar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docState = ref.watch(documentProvider);
    final navState = ref.watch(navigationProvider);
    final zoomState = ref.watch(zoomProvider);
    final searchState = ref.watch(searchProvider);
    final settingsState = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerTheme.color ?? Colors.grey.shade300),
        ),
      ),
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent && _scrollController.hasClients) {
            final target = (_scrollController.offset + pointerSignal.scrollDelta.dy)
                .clamp(0.0, _scrollController.position.maxScrollExtent);
            _scrollController.jumpTo(target);
          }
        },
        child: Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Sidebar Toggle
                IconButton(
                  icon: Icon(
                    settingsState.isSidebarOpen ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                    size: 20,
                  ),
                  tooltip: 'Toggle Sidebar',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ref.read(settingsProvider.notifier).toggleSidebar(),
                ),

                const SizedBox(width: 2),

                // 2. File Operations
                IconButton(
                  icon: const Icon(Icons.folder_open_outlined, size: 20),
                  tooltip: 'Open PDF (Ctrl+O)',
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    final path = await FileService.pickPdfFile();
                    if (path != null) {
                      await ref.read(documentProvider.notifier).openFile(path);
                    }
                  },
                ),

                if (docState.hasDocument) ...[
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Clear / Close PDF (Ctrl+W)',
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      await ref.read(documentProvider.notifier).closeDocument();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.save_outlined, size: 20),
                    tooltip: 'Save Annotations (Ctrl+S)',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _handleSave(context, ref, saveAs: false),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save_as_outlined, size: 20),
                    tooltip: 'Save As (Ctrl+Shift+S)',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _handleSave(context, ref, saveAs: true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.print_outlined, size: 20),
                    tooltip: 'Print (Ctrl+P)',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _handlePrint(context, ref),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 20),
                    tooltip: 'Share Document',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _handleShare(context, ref),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 20),
                    tooltip: 'Document Properties',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => DocumentPropertiesDialog.show(context, docState.metadata),
                  ),
                ],

                const SizedBox(width: 4),

                // 3. All PDF Tools Button (Prominent with Text Label)
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.grid_view_outlined, size: 16),
                  label: const Text('All Tools', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  onPressed: () => QuickToolsDialog.show(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    minimumSize: const Size(0, 32),
                    visualDensity: VisualDensity.compact,
                  ),
                ),

                const VerticalDivider(width: 14, indent: 10, endIndent: 10),

                // 4. Page Navigation Controls (With Visible Text)
                if (docState.hasDocument) ...[
                  IconButton(
                    icon: const Icon(Icons.first_page, size: 20),
                    tooltip: 'First Page',
                    visualDensity: VisualDensity.compact,
                    onPressed: navState.currentPage > 1
                        ? () => ref.read(navigationProvider.notifier).firstPage()
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.navigate_before, size: 20),
                    tooltip: 'Previous Page (PgUp)',
                    visualDensity: VisualDensity.compact,
                    onPressed: navState.currentPage > 1
                        ? () => ref.read(navigationProvider.notifier).prevPage()
                        : null,
                  ),

                  // Page Indicator with Text & Go-To Action
                  Tooltip(
                    message: 'Go to page...',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () async {
                        final target = await GoToPageDialog.show(
                          context,
                          navState.currentPage,
                          navState.totalPages,
                        );
                        if (target != null) {
                          ref.read(navigationProvider.notifier).setPage(target);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Page ${navState.currentPage} / ${navState.totalPages}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.navigate_next, size: 20),
                    tooltip: 'Next Page (PgDn)',
                    visualDensity: VisualDensity.compact,
                    onPressed: navState.currentPage < navState.totalPages
                        ? () => ref.read(navigationProvider.notifier).nextPage()
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page, size: 20),
                    tooltip: 'Last Page',
                    visualDensity: VisualDensity.compact,
                    onPressed: navState.currentPage < navState.totalPages
                        ? () => ref.read(navigationProvider.notifier).lastPage()
                        : null,
                  ),

                  const VerticalDivider(width: 14, indent: 10, endIndent: 10),

                  // 5. Zoom & Fit Controls (With Visible Text)
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    tooltip: 'Zoom Out (Ctrl+-)',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => ref.read(zoomProvider.notifier).zoomOut(),
                  ),

                  // Zoom Preset Dropdown with Visible Percentage
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<double>(
                        value: AppConstants.zoomPresets.contains(zoomState.scale)
                            ? zoomState.scale
                            : null,
                        hint: Text(
                          '${(zoomState.scale * 100).toInt()}%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        items: AppConstants.zoomPresets.map((preset) {
                          return DropdownMenuItem<double>(
                            value: preset,
                            child: Text(
                              '${(preset * 100).toInt()}%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(zoomProvider.notifier).setZoom(val);
                          }
                        },
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    tooltip: 'Zoom In (Ctrl++)',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => ref.read(zoomProvider.notifier).zoomIn(),
                  ),

                  IconButton(
                    icon: Icon(
                      zoomState.fitMode == FitMode.fitWidth ? Icons.fit_screen : Icons.fit_screen_outlined,
                      size: 18,
                      color: zoomState.fitMode == FitMode.fitWidth ? theme.colorScheme.primary : null,
                    ),
                    tooltip: 'Fit Width (Ctrl+1)',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => ref.read(zoomProvider.notifier).setFitMode(FitMode.fitWidth),
                  ),
                  IconButton(
                    icon: Icon(
                      zoomState.fitMode == FitMode.fitContent ? Icons.center_focus_strong : Icons.center_focus_strong_outlined,
                      size: 18,
                      color: zoomState.fitMode == FitMode.fitContent ? theme.colorScheme.primary : null,
                    ),
                    tooltip: 'Fit Content (Ctrl+2)',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => ref.read(zoomProvider.notifier).setFitMode(FitMode.fitContent),
                  ),
                  IconButton(
                    icon: Icon(
                      zoomState.fitMode == FitMode.fitPage ? Icons.fullscreen_exit : Icons.crop_free,
                      size: 18,
                      color: zoomState.fitMode == FitMode.fitPage ? theme.colorScheme.primary : null,
                    ),
                    tooltip: 'Fit Page (Ctrl+0)',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => ref.read(zoomProvider.notifier).setFitMode(FitMode.fitPage),
                  ),
                  IconButton(
                    icon: Icon(
                      zoomState.trimWhiteMargins ? Icons.crop : Icons.crop_outlined,
                      size: 18,
                      color: zoomState.trimWhiteMargins ? theme.colorScheme.primary : null,
                    ),
                    tooltip: zoomState.trimWhiteMargins
                        ? 'Trimming White Margins (Content Focused) [Ctrl+M]'
                        : 'Trim White Margins (Zoom inside content) [Ctrl+M]',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => ref.read(zoomProvider.notifier).toggleTrimWhiteMargins(),
                  ),

                  // Upscale PDF Resolution Option with Visible Text Badge
                  PopupMenuButton<double>(
                    tooltip: 'Upscale PDF Resolution (Ctrl+U) - Super Clarity',
                    onSelected: (factor) {
                      ref.read(zoomProvider.notifier).setUpscaleFactor(factor);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 1),
                          content: Text('PDF Upscaled: ${factor}x Super Clarity'),
                        ),
                      );
                    },
                    itemBuilder: (context) => [
                      CheckedPopupMenuItem<double>(
                        value: 1.0,
                        checked: zoomState.upscaleFactor == 1.0,
                        child: const Text('1.0x - Standard (Fast)'),
                      ),
                      CheckedPopupMenuItem<double>(
                        value: 1.5,
                        checked: zoomState.upscaleFactor == 1.5,
                        child: const Text('1.5x - Enhanced HD (Balanced)'),
                      ),
                      CheckedPopupMenuItem<double>(
                        value: 2.0,
                        checked: zoomState.upscaleFactor == 2.0,
                        child: const Text('2.0x - Ultra Sharp (Crisp & Clear)'),
                      ),
                      CheckedPopupMenuItem<double>(
                        value: 3.0,
                        checked: zoomState.upscaleFactor == 3.0,
                        child: const Text('3.0x - Maximum Clarity (Super-Sampling)'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: zoomState.upscaleFactor > 1.0
                            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.7)
                            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: zoomState.upscaleFactor > 1.0
                              ? theme.colorScheme.primary.withValues(alpha: 0.6)
                              : theme.dividerTheme.color ?? Colors.grey.shade400,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: zoomState.upscaleFactor > 1.0
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${zoomState.upscaleFactor}x HD',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: zoomState.upscaleFactor > 1.0
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 14,
                            color: zoomState.upscaleFactor > 1.0
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const VerticalDivider(width: 14, indent: 10, endIndent: 10),

                  // 6. Layout & Rotation Controls
                  IconButton(
                    icon: Icon(
                      navState.layoutMode == PageLayoutMode.singlePage
                          ? Icons.looks_one_outlined
                          : navState.layoutMode == PageLayoutMode.continuousVertical
                              ? Icons.view_day_outlined
                              : Icons.menu_book_outlined,
                      size: 20,
                    ),
                    tooltip: 'Page Layout Mode',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      final nextMode = navState.layoutMode == PageLayoutMode.singlePage
                          ? PageLayoutMode.continuousVertical
                          : navState.layoutMode == PageLayoutMode.continuousVertical
                              ? PageLayoutMode.twoPageSpread
                              : PageLayoutMode.singlePage;
                      ref.read(navigationProvider.notifier).setLayoutMode(nextMode);
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.rotate_right, size: 20),
                    tooltip: 'Rotate Clockwise (Ctrl+R)',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => ref.read(navigationProvider.notifier).rotateClockwise(),
                  ),

                  const VerticalDivider(width: 14, indent: 10, endIndent: 10),

                  // 7. Search Action (With Visible Text)
                  OutlinedButton.icon(
                    icon: Icon(
                      searchState.isOpen ? Icons.search : Icons.search_outlined,
                      size: 16,
                      color: searchState.isOpen ? theme.colorScheme.primary : null,
                    ),
                    label: Text(
                      'Search',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: searchState.isOpen ? theme.colorScheme.primary : null,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: const Size(0, 32),
                      visualDensity: VisualDensity.compact,
                      side: searchState.isOpen
                          ? BorderSide(color: theme.colorScheme.primary)
                          : null,
                    ),
                    onPressed: () {
                      ref.read(searchProvider.notifier).toggleSearch();
                      if (!searchState.isOpen) {
                        ref.read(settingsProvider.notifier).setSidebarTab(4); // Open search tab
                      }
                    },
                  ),

                  const SizedBox(width: 4),

                  // 8. Annotation Ribbon Toggle (With Visible Text)
                  FilledButton.tonalIcon(
                    icon: Icon(
                      Icons.edit_note,
                      size: 18,
                      color: settingsState.isAnnotationRibbonOpen ? Colors.white : null,
                    ),
                    label: Text(
                      'Annotate',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: settingsState.isAnnotationRibbonOpen ? Colors.white : null,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: settingsState.isAnnotationRibbonOpen
                          ? theme.colorScheme.primary
                          : null,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      minimumSize: const Size(0, 32),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => ref.read(settingsProvider.notifier).toggleAnnotationRibbon(),
                  ),

                  const VerticalDivider(width: 14, indent: 10, endIndent: 10),
                ],

                // 9. Presentation Mode, Theme Switcher & More Menu
                if (docState.hasDocument)
                  IconButton(
                    icon: Icon(
                      settingsState.isPresentationMode ? Icons.slideshow : Icons.slideshow_outlined,
                      size: 20,
                    ),
                    tooltip: 'Presentation Mode (F5)',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => ref.read(settingsProvider.notifier).togglePresentationMode(),
                  ),

                PopupMenuButton<AppThemeMode>(
                  icon: Icon(
                    settingsState.themeMode == AppThemeMode.corporate
                        ? Icons.business_center_outlined
                        : settingsState.themeMode == AppThemeMode.dark
                            ? Icons.dark_mode_outlined
                            : settingsState.themeMode == AppThemeMode.sepia
                                ? Icons.menu_book
                                : Icons.light_mode_outlined,
                    size: 20,
                  ),
                  tooltip: 'Appearance Theme',
                  onSelected: (mode) => ref.read(settingsProvider.notifier).setTheme(mode),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: AppThemeMode.corporate,
                      child: Row(
                        children: [Icon(Icons.business_center_outlined, size: 18), SizedBox(width: 8), Text('Corporate (Navy)')],
                      ),
                    ),
                    const PopupMenuItem(
                      value: AppThemeMode.light,
                      child: Row(
                        children: [Icon(Icons.light_mode_outlined, size: 18), SizedBox(width: 8), Text('Light Theme')],
                      ),
                    ),
                    const PopupMenuItem(
                      value: AppThemeMode.dark,
                      child: Row(
                        children: [Icon(Icons.dark_mode_outlined, size: 18), SizedBox(width: 8), Text('Dark Theme')],
                      ),
                    ),
                    const PopupMenuItem(
                      value: AppThemeMode.sepia,
                      child: Row(
                        children: [Icon(Icons.menu_book, size: 18), SizedBox(width: 8), Text('Sepia / Eye-Care')],
                      ),
                    ),
                  ],
                ),

                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  tooltip: 'More Actions',
                  onSelected: (val) async {
                    if (val == 'open_sample') {
                      await ref.read(documentProvider.notifier).openSample();
                    } else if (val == 'close') {
                      await ref.read(documentProvider.notifier).closeDocument();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'open_sample',
                      child: Row(
                        children: [Icon(Icons.description_outlined, size: 18), SizedBox(width: 8), Text('Open Sample PDF')],
                      ),
                    ),
                    if (docState.hasDocument)
                      const PopupMenuItem(
                        value: 'close',
                        child: Row(
                          children: [Icon(Icons.close, size: 18), SizedBox(width: 8), Text('Close Document')],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave(BuildContext context, WidgetRef ref, {required bool saveAs}) async {
    final docState = ref.read(documentProvider);
    final annotations = ref.read(annotationProvider).annotations;
    if (docState.currentBytes == null) return;

    try {
      final exportedBytes = await PdfExportService.exportAnnotatedPdf(
        originalBytes: docState.currentBytes!,
        annotations: annotations,
      );

      final docTitle = docState.metadata.title.isNotEmpty ? docState.metadata.title : 'document.pdf';

      if (!saveAs && docState.currentPath != null && docState.currentPath!.isNotEmpty) {
        await PdfExportService.saveToDisk(exportedBytes, docState.currentPath!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Document successfully saved to ${docState.currentPath}')),
          );
        }
      } else {
        final savedPath = await FileService.savePdfFile(
          fileName: docTitle.endsWith('.pdf') ? docTitle : '$docTitle.pdf',
          bytes: exportedBytes,
        );
        if (savedPath != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Document saved to $savedPath')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save document: $e')),
        );
      }
    }
  }

  Future<void> _handlePrint(BuildContext context, WidgetRef ref) async {
    final docState = ref.read(documentProvider);
    final annotations = ref.read(annotationProvider).annotations;
    if (docState.currentBytes == null) return;

    try {
      final printBytes = await PdfExportService.exportAnnotatedPdf(
        originalBytes: docState.currentBytes!,
        annotations: annotations,
      );
      await PrintService.printPdf(printBytes, name: docState.metadata.title);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Printing failed: $e')),
        );
      }
    }
  }

  Future<void> _handleShare(BuildContext context, WidgetRef ref) async {
    final docState = ref.read(documentProvider);
    if (docState.currentPath != null && docState.currentPath!.isNotEmpty) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(docState.currentPath!)],
          text: docState.metadata.title,
        ),
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please save document first to share file.')),
        );
      }
    }
  }
}
