import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/shortcuts/app_shortcuts.dart';
import '../../../services/file_service.dart';
import '../../../services/pdf/pdf_export_service.dart';
import '../../../services/print_service.dart';
import '../../../state/annotation_provider.dart';
import '../../../state/bookmark_provider.dart';
import '../../../state/document_provider.dart';
import '../../../state/navigation_provider.dart';
import '../../../state/search_provider.dart';
import '../../../state/settings_provider.dart';
import '../../../state/zoom_provider.dart';
import '../widgets/annotation_ribbon/annotation_ribbon.dart';
import '../widgets/canvas/pdf_canvas_view.dart';
import '../widgets/sidebar/navigation_sidebar.dart';
import '../widgets/toolbar/main_toolbar.dart';
import 'welcome_screen.dart';

class ViewerScreen extends ConsumerStatefulWidget {
  const ViewerScreen({super.key});

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docState = ref.watch(documentProvider);
    final settingsState = ref.watch(settingsProvider);

    // Sync outline & annotations when document changes
    ref.listen<DocumentState>(documentProvider, (previous, next) {
      if (next.hasDocument && previous?.currentPath != next.currentPath) {
        ref.read(bookmarkProvider.notifier).loadForDocument(next.currentPath, next.engine);
        if (next.currentPath != null) {
          ref.read(annotationProvider.notifier).loadAnnotationsForDocument(next.currentPath!);
        }
      }
    });

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        // Ctrl+O: Open
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyO): const OpenFileIntent(),
        // Ctrl+S: Save
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): const SaveFileIntent(),
        // Ctrl+P: Print
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP): const PrintFileIntent(),
        // Ctrl+F: Search
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const SearchFileIntent(),
        // Ctrl+Z: Undo
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): const UndoIntent(),
        // Ctrl+Y: Redo
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY): const RedoIntent(),
        // Ctrl+Shift+Z: Redo
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyZ): const RedoIntent(),
        // Upscale
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyU): const UpscaleToggleIntent(),
        // Close / Clear PDF
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyW): const CloseFileIntent(),
        // Zoom
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.equal): const ZoomInIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.minus): const ZoomOutIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit0): const ZoomResetIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit1): const FitWidthIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit2): const FitContentIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyM): const TrimMarginsIntent(),
        // Rotate
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): const RotateClockwiseIntent(),
        // Presentation & Fullscreen
        LogicalKeySet(LogicalKeyboardKey.f5): const PresentationToggleIntent(),
        LogicalKeySet(LogicalKeyboardKey.f11): const FullscreenToggleIntent(),
        // Navigation
        LogicalKeySet(LogicalKeyboardKey.pageUp): const PrevPageIntent(),
        LogicalKeySet(LogicalKeyboardKey.pageDown): const NextPageIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const PrevPageIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const NextPageIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          OpenFileIntent: CallbackAction<OpenFileIntent>(
            onInvoke: (_) async {
              final path = await FileService.pickPdfFile();
              if (path != null) {
                await ref.read(documentProvider.notifier).openFile(path);
              }
              return null;
            },
          ),
          SaveFileIntent: CallbackAction<SaveFileIntent>(
            onInvoke: (_) async {
              _saveDoc(context, ref);
              return null;
            },
          ),
          PrintFileIntent: CallbackAction<PrintFileIntent>(
            onInvoke: (_) async {
              _printDoc(context, ref);
              return null;
            },
          ),
          SearchFileIntent: CallbackAction<SearchFileIntent>(
            onInvoke: (_) {
              ref.read(searchProvider.notifier).toggleSearch();
              ref.read(settingsProvider.notifier).setSidebarTab(4);
              return null;
            },
          ),
          UndoIntent: CallbackAction<UndoIntent>(
            onInvoke: (_) {
              ref.read(annotationProvider.notifier).undo();
              return null;
            },
          ),
          RedoIntent: CallbackAction<RedoIntent>(
            onInvoke: (_) {
              ref.read(annotationProvider.notifier).redo();
              return null;
            },
          ),
          ZoomInIntent: CallbackAction<ZoomInIntent>(
            onInvoke: (_) {
              ref.read(zoomProvider.notifier).zoomIn();
              return null;
            },
          ),
          ZoomOutIntent: CallbackAction<ZoomOutIntent>(
            onInvoke: (_) {
              ref.read(zoomProvider.notifier).zoomOut();
              return null;
            },
          ),
          ZoomResetIntent: CallbackAction<ZoomResetIntent>(
            onInvoke: (_) {
              ref.read(zoomProvider.notifier).setFitMode(FitMode.fitPage);
              return null;
            },
          ),
          FitWidthIntent: CallbackAction<FitWidthIntent>(
            onInvoke: (_) {
              ref.read(zoomProvider.notifier).setFitMode(FitMode.fitWidth);
              return null;
            },
          ),
          FitContentIntent: CallbackAction<FitContentIntent>(
            onInvoke: (_) {
              ref.read(zoomProvider.notifier).setFitMode(FitMode.fitContent);
              return null;
            },
          ),
          TrimMarginsIntent: CallbackAction<TrimMarginsIntent>(
            onInvoke: (_) {
              ref.read(zoomProvider.notifier).toggleTrimWhiteMargins();
              return null;
            },
          ),
          RotateClockwiseIntent: CallbackAction<RotateClockwiseIntent>(
            onInvoke: (_) {
              ref.read(navigationProvider.notifier).rotateClockwise();
              return null;
            },
          ),
          PresentationToggleIntent: CallbackAction<PresentationToggleIntent>(
            onInvoke: (_) {
              ref.read(settingsProvider.notifier).togglePresentationMode();
              return null;
            },
          ),
          FullscreenToggleIntent: CallbackAction<FullscreenToggleIntent>(
            onInvoke: (_) {
              ref.read(settingsProvider.notifier).toggleFullscreen();
              return null;
            },
          ),
          PrevPageIntent: CallbackAction<PrevPageIntent>(
            onInvoke: (_) {
              ref.read(navigationProvider.notifier).prevPage();
              return null;
            },
          ),
          NextPageIntent: CallbackAction<NextPageIntent>(
            onInvoke: (_) {
              ref.read(navigationProvider.notifier).nextPage();
              return null;
            },
          ),
          UpscaleToggleIntent: CallbackAction<UpscaleToggleIntent>(
            onInvoke: (_) {
              ref.read(zoomProvider.notifier).cycleUpscale();
              final factor = ref.read(zoomProvider).upscaleFactor;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 1),
                  content: Text('PDF Upscale: ${factor}x Super Clarity'),
                ),
              );
              return null;
            },
          ),
          CloseFileIntent: CallbackAction<CloseFileIntent>(
            onInvoke: (_) async {
              await ref.read(documentProvider.notifier).closeDocument();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  // Top Toolbar (hidden in presentation mode)
                  if (!settingsState.isPresentationMode) const MainToolbar(),

                  // Annotation Ribbon (hidden in presentation mode)
                  if (!settingsState.isPresentationMode) const AnnotationRibbon(),

                  // Central Workspace (Sidebar + Canvas, or Welcome Screen)
                  Expanded(
                    child: docState.hasDocument
                        ? const Row(
                            children: [
                              NavigationSidebar(),
                              Expanded(child: PdfCanvasView()),
                            ],
                          )
                        : const WelcomeScreen(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveDoc(BuildContext context, WidgetRef ref) async {
    final docState = ref.read(documentProvider);
    final annotations = ref.read(annotationProvider).annotations;
    if (docState.currentBytes == null) return;

    try {
      final exportedBytes = await PdfExportService.exportAnnotatedPdf(
        originalBytes: docState.currentBytes!,
        annotations: annotations,
      );

      final docTitle = docState.metadata.title.isNotEmpty ? docState.metadata.title : 'document.pdf';

      if (docState.currentPath != null && docState.currentPath!.isNotEmpty) {
        await PdfExportService.saveToDisk(exportedBytes, docState.currentPath!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Document saved to ${docState.currentPath}')),
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
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _printDoc(BuildContext context, WidgetRef ref) async {
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
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }
}
