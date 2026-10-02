import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/annotation_model.dart';
import '../../../services/pdf/pdf_converter_service.dart';
import '../../../state/annotation_provider.dart';
import '../../../state/document_provider.dart';
import '../../../state/navigation_provider.dart';
import '../../../state/zoom_provider.dart';

class PdfCanvasView extends ConsumerStatefulWidget {
  const PdfCanvasView({super.key});

  @override
  ConsumerState<PdfCanvasView> createState() => _PdfCanvasViewState();
}

class _PdfCanvasViewState extends ConsumerState<PdfCanvasView> {
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final Map<int, Uint8List?> _pageRenderCache = {};
  final Map<int, Uint8List> _lastRenderedPage = {};
  final Map<int, Size> _pageDimensionsCache = {};
  final Map<int, String> _pageTextCache = {};
  final Map<int, List<PdfTextLine>> _pageLinesCache = {};
  int? _hoveredPage;
  PointerDeviceKind _lastPointerKind = PointerDeviceKind.mouse;
  String? _activeDocKey;
  double? _lastUpscaleFactor;
  double? _previousScale;
  double _basePinchScale = 1.0;
  int? _lastPage;

  // For active drawing
  Offset? _dragStart;
  Offset? _dragCurrent;
  final List<DrawingPoint> _activeInkPoints = [];

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _prefetchPageData(DocumentState docState) {
    if (!docState.hasDocument) return;
    for (int p = 1; p <= docState.engine.pageCount; p++) {
      if (!_pageDimensionsCache.containsKey(p)) {
        docState.engine.getPageDimensions(p).then((size) {
          if (mounted && _pageDimensionsCache[p] != size) {
            setState(() {
              _pageDimensionsCache[p] = size;
            });
          }
        });
      }
      if (!_pageTextCache.containsKey(p)) {
        docState.engine.extractText(p).then((text) {
          if (mounted && _pageTextCache[p] != text) {
            setState(() {
              _pageTextCache[p] = text;
            });
          }
        });
        docState.engine.extractPageLines(p).then((lines) {
          if (mounted && lines.isNotEmpty) {
            setState(() {
              _pageLinesCache[p] = lines;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docState = ref.watch(documentProvider);
    final navState = ref.watch(navigationProvider);
    final zoomState = ref.watch(zoomProvider);
    final annoState = ref.watch(annotationProvider);
    final theme = Theme.of(context);

    // Clear caches when document changes or document is closed
    final currentDocKey = '${docState.currentPath ?? ''}_${docState.engine.pageCount}';
    if (_activeDocKey != currentDocKey) {
      _pageRenderCache.clear();
      _lastRenderedPage.clear();
      _pageDimensionsCache.clear();
      _pageTextCache.clear();
      _pageLinesCache.clear();
      _activeDocKey = currentDocKey;
      _previousScale = null;
      _lastPage = null;
    }

    if (docState.hasDocument) {
      _prefetchPageData(docState);
    }

    // Invalidate render cache when upscale factor changes so pages re-render in super-clarity
    if (_lastUpscaleFactor != null && _lastUpscaleFactor != zoomState.upscaleFactor) {
      _pageRenderCache.clear();
    }
    _lastUpscaleFactor = zoomState.upscaleFactor;

    if (docState.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Rendering PDF pages...'),
          ],
        ),
      );
    }

    if (!docState.hasDocument) {
      _pageRenderCache.clear();
      _lastRenderedPage.clear();
      _pageDimensionsCache.clear();
      return const SizedBox.shrink();
    }

    final totalPages = docState.engine.pageCount;
    if (navState.totalPages != totalPages) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(navigationProvider.notifier).setTotalPages(totalPages);
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Base dimensions from cache or default A4
        final firstPageSize = _pageDimensionsCache[navState.currentPage] ?? const Size(595.0, 842.0);
        final baseWidth = firstPageSize.width;
        final baseHeight = firstPageSize.height;

        double effectiveScale = zoomState.scale;
        if (zoomState.fitMode == FitMode.fitWidth) {
          final availableWidth = navState.layoutMode == PageLayoutMode.twoPageSpread
              ? (constraints.maxWidth - 48.0 - 16.0) / 2
              : (constraints.maxWidth - 48.0);
          effectiveScale = (availableWidth / baseWidth).clamp(0.2, 5.0);
        } else if (zoomState.fitMode == FitMode.fitContent) {
          final availableWidth = navState.layoutMode == PageLayoutMode.twoPageSpread
              ? (constraints.maxWidth - 32.0 - 16.0) / 2
              : (constraints.maxWidth - 32.0);
          effectiveScale = (availableWidth / (baseWidth * 0.85)).clamp(0.2, 5.0);
        } else if (zoomState.fitMode == FitMode.fitPage) {
          final availableHeight = constraints.maxHeight - 48.0;
          effectiveScale = (availableHeight / baseHeight).clamp(0.2, 5.0);
        }

        final dpr = (MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0).clamp(1.5, 3.5);

        // Center on previous focal point when zooming
        if (_previousScale != null && _previousScale != effectiveScale && _previousScale! > 0) {
          final ratio = effectiveScale / _previousScale!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_horizontalScrollController.hasClients && _verticalScrollController.hasClients) {
              final curX = _horizontalScrollController.offset;
              final curY = _verticalScrollController.offset;
              final viewW = constraints.maxWidth;
              final viewH = constraints.maxHeight;

              final targetX = ((curX + viewW / 2) * ratio - viewW / 2)
                  .clamp(0.0, _horizontalScrollController.position.maxScrollExtent);
              final targetY = ((curY + viewH / 2) * ratio - viewH / 2)
                  .clamp(0.0, _verticalScrollController.position.maxScrollExtent);

              _horizontalScrollController.jumpTo(targetX);
              _verticalScrollController.jumpTo(targetY);
            }
          });
        }
        _previousScale = effectiveScale;

        // Reset scroll position to top when navigating to a different page in singlePage mode
        if (_lastPage != navState.currentPage) {
          _lastPage = navState.currentPage;
          if (navState.layoutMode == PageLayoutMode.singlePage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_verticalScrollController.hasClients) {
                _verticalScrollController.jumpTo(0.0);
              }
            });
          }
        }

        return Listener(
          onPointerDown: (e) {
            _lastPointerKind = e.kind;
          },
          onPointerPanZoomStart: (e) {
            _basePinchScale = effectiveScale;
          },
          onPointerPanZoomUpdate: (e) {
            // Precision Touchpad (Trackpad) gestures on Windows / macOS / Linux:
            if (e.scale != 1.0) {
              // 2-finger touchpad pinch to zoom
              final targetZoom = (_basePinchScale * e.scale).clamp(0.25, 5.0);
              ref.read(zoomProvider.notifier).setZoom(targetZoom);
            } else {
              // 2-finger touchpad panning / smooth scrolling
              if (_verticalScrollController.hasClients && e.panDelta.dy.abs() > 0) {
                final newY = (_verticalScrollController.offset - e.panDelta.dy)
                    .clamp(0.0, _verticalScrollController.position.maxScrollExtent);
                _verticalScrollController.jumpTo(newY);
              }
              if (_horizontalScrollController.hasClients && e.panDelta.dx.abs() > 0) {
                final newX = (_horizontalScrollController.offset - e.panDelta.dx)
                    .clamp(0.0, _horizontalScrollController.position.maxScrollExtent);
                _horizontalScrollController.jumpTo(newX);
              }
            }
          },
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              if (HardwareKeyboard.instance.isControlPressed) {
                // Ctrl + Touchpad scroll / Mouse wheel -> Zoom
                if (pointerSignal.scrollDelta.dy < 0) {
                  ref.read(zoomProvider.notifier).zoomIn();
                } else if (pointerSignal.scrollDelta.dy > 0) {
                  ref.read(zoomProvider.notifier).zoomOut();
                }
              } else if (HardwareKeyboard.instance.isShiftPressed) {
                // Shift + wheel -> horizontal scroll
                if (_horizontalScrollController.hasClients) {
                  final newOffset = (_horizontalScrollController.offset + pointerSignal.scrollDelta.dy)
                      .clamp(0.0, _horizontalScrollController.position.maxScrollExtent);
                  _horizontalScrollController.jumpTo(newOffset);
                }
              } else {
                // Touchpad 2-finger scroll and Mouse wheel
                if (_verticalScrollController.hasClients && pointerSignal.scrollDelta.dy.abs() > 0) {
                  final newY = (_verticalScrollController.offset + pointerSignal.scrollDelta.dy)
                      .clamp(0.0, _verticalScrollController.position.maxScrollExtent);
                  _verticalScrollController.jumpTo(newY);
                }
                if (_horizontalScrollController.hasClients && pointerSignal.scrollDelta.dx.abs() > 0) {
                  final newX = (_horizontalScrollController.offset + pointerSignal.scrollDelta.dx)
                      .clamp(0.0, _horizontalScrollController.position.maxScrollExtent);
                  _horizontalScrollController.jumpTo(newX);
                }
              }
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onScaleStart: (details) {
              _basePinchScale = effectiveScale;
            },
            onScaleUpdate: (details) {
              if (details.pointerCount >= 2) {
                // Multi-finger pinch-to-zoom on touch screens & tablets
                final targetZoom = (_basePinchScale * details.scale).clamp(0.25, 5.0);
                ref.read(zoomProvider.notifier).setZoom(targetZoom);
              } else if (annoState.activeTool == AnnotationTool.select &&
                  (_lastPointerKind == PointerDeviceKind.touch || _lastPointerKind == PointerDeviceKind.trackpad)) {
                // Single-finger touch pan / scroll on touch screen / mobile / tablet
                if (_horizontalScrollController.hasClients) {
                  final newX = (_horizontalScrollController.offset - details.focalPointDelta.dx)
                      .clamp(0.0, _horizontalScrollController.position.maxScrollExtent);
                  _horizontalScrollController.jumpTo(newX);
                }
                if (_verticalScrollController.hasClients) {
                  final newY = (_verticalScrollController.offset - details.focalPointDelta.dy)
                      .clamp(0.0, _verticalScrollController.position.maxScrollExtent);
                  _verticalScrollController.jumpTo(newY);
                }
              }
            },
            onDoubleTap: () {
              // Quick double-tap zoom toggle for mobile / tablet touch devices
              if (effectiveScale > 1.25) {
                ref.read(zoomProvider.notifier).setFitMode(FitMode.fitWidth);
              } else {
                ref.read(zoomProvider.notifier).setZoom(1.8);
              }
            },
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: ScrollbarTheme(
                data: ScrollbarThemeData(
                  thumbVisibility: const WidgetStatePropertyAll<bool>(false),
                  trackVisibility: const WidgetStatePropertyAll<bool>(false),
                  thickness: const WidgetStatePropertyAll<double>(8.0),
                  radius: const Radius.circular(4.0),
                  thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.dragged)) {
                      return theme.colorScheme.primary;
                    }
                    if (states.contains(WidgetState.hovered)) {
                      return theme.colorScheme.primary.withValues(alpha: 0.8);
                    }
                    return theme.colorScheme.onSurface.withValues(alpha: 0.35);
                  }),
                  trackColor: WidgetStatePropertyAll<Color>(
                    theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  ),
                  trackBorderColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
                ),
                child: Scrollbar(
                  controller: _verticalScrollController,
                  notificationPredicate: (notif) => notif.metrics.axis == Axis.vertical,
                  child: SingleChildScrollView(
                    controller: _verticalScrollController,
                    scrollDirection: Axis.vertical,
                    physics: const ClampingScrollPhysics(),
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                          minHeight: constraints.maxHeight,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                        child: _buildLayoutMode(
                          navState,
                          docState,
                          annoState,
                          effectiveScale,
                          dpr,
                          zoomState.upscaleFactor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayoutMode(
    NavigationState navState,
    DocumentState docState,
    AnnotationState annoState,
    double scale,
    double dpr,
    double upscaleFactor,
  ) {
    switch (navState.layoutMode) {
      case PageLayoutMode.singlePage:
        return _buildSinglePage(navState.currentPage, docState, annoState, scale, dpr, navState.rotation, upscaleFactor);

      case PageLayoutMode.twoPageSpread:
        final p1 = navState.currentPage;
        final p2 = (p1 + 1 <= docState.engine.pageCount) ? p1 + 1 : null;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSinglePage(p1, docState, annoState, scale, dpr, navState.rotation, upscaleFactor),
            if (p2 != null) ...[
              const SizedBox(width: 16),
              _buildSinglePage(p2, docState, annoState, scale, dpr, navState.rotation, upscaleFactor),
            ],
          ],
        );

      case PageLayoutMode.continuousVertical:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(docState.engine.pageCount, (index) {
            final pageNum = index + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _buildSinglePage(pageNum, docState, annoState, scale, dpr, navState.rotation, upscaleFactor),
            );
          }),
        );
    }
  }

  Widget _buildSinglePage(
    int pageNum,
    DocumentState docState,
    AnnotationState annoState,
    double scale,
    double dpr,
    int rotation,
    double upscaleFactor,
  ) {
    final theme = Theme.of(context);
    // Base A4 dimensions in PDF points
    const baseWidth = 595.0;
    const baseHeight = 842.0;

    final pageSize = _pageDimensionsCache[pageNum] ?? const Size(baseWidth, baseHeight);

    final fullWidth = pageSize.width * scale;
    final fullHeight = pageSize.height * scale;

    final pageAnnotations = annoState.getAnnotationsForPage(pageNum);

    // Dynamic resolution bucket key for instant cache hit
    final effectiveDpr = math.max(2.0, dpr);
    final calculatedWidth = (fullWidth * effectiveDpr * upscaleFactor).round();
    final minResolution = (1800 * upscaleFactor).round();
    final maxResolution = (4800 * math.min(upscaleFactor, 2.0)).clamp(4096, 7200).toInt();
    final renderWidth = calculatedWidth.clamp(minResolution, maxResolution);
    final bucketedWidth = ((renderWidth + 63) ~/ 64) * 64;
    final key = pageNum * 100000 + bucketedWidth;
    final cachedBytes = _pageRenderCache[key];

    return Transform.rotate(
      angle: rotation * (math.pi / 180),
      child: Container(
        width: fullWidth,
        height: fullHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              // 1. PDF Page Render Layer (Crystal Clear High Quality with Upscaling)
              Positioned.fill(
                child: cachedBytes != null
                    ? Image.memory(
                        cachedBytes,
                        width: fullWidth,
                        height: fullHeight,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                      )
                    : FutureBuilder<Uint8List?>(
                        future: _renderPage(docState, pageNum, fullWidth, fullHeight, dpr, upscaleFactor),
                        builder: (context, snapshot) {
                          final displayBytes = snapshot.data ?? _lastRenderedPage[pageNum];
                          if (displayBytes != null) {
                            return Image.memory(
                              displayBytes,
                              width: fullWidth,
                              height: fullHeight,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              gaplessPlayback: true,
                            );
                          }
                          return Container(
                            color: Colors.white,
                            child: const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // 2. Saved Annotations Layer
              Positioned.fill(
                child: CustomPaint(
                  painter: _AnnotationsPainter(
                    annotations: pageAnnotations,
                    scale: scale,
                    selectedId: annoState.selectedAnnotation?.id,
                  ),
                ),
              ),

              // 3. Interactive Selectable Text Layer (Active when Select tool is chosen)
              if (annoState.activeTool == AnnotationTool.select)
                Positioned.fill(
                  child: _buildSelectableTextLayer(
                    pageNum: pageNum,
                    pageSize: pageSize,
                    scale: scale,
                    theme: theme,
                    docState: docState,
                  ),
                ),

              // 4. Active Drawing / Gesture Layer (Active when drawing/annotating)
              if (annoState.activeTool != AnnotationTool.select)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onScaleStart: (details) {
                      if (details.pointerCount >= 2) {
                        // Touch screen multi-finger pinch: cancel any drawing stroke
                        setState(() {
                          _dragStart = null;
                          _dragCurrent = null;
                          _activeInkPoints.clear();
                        });
                        _basePinchScale = scale;
                        return;
                      }
                      setState(() {
                        _dragStart = details.localFocalPoint;
                        _dragCurrent = details.localFocalPoint;
                        if (annoState.activeTool == AnnotationTool.ink) {
                          _activeInkPoints.clear();
                          _activeInkPoints.add(DrawingPoint(
                            details.localFocalPoint.dx / scale,
                            details.localFocalPoint.dy / scale,
                          ));
                        }
                      });
                    },
                    onScaleUpdate: (details) {
                      if (details.pointerCount >= 2) {
                        // Pinch-to-zoom even while in annotation mode on touch screen
                        final targetZoom = (_basePinchScale * details.scale).clamp(0.25, 5.0);
                        ref.read(zoomProvider.notifier).setZoom(targetZoom);
                        return;
                      }
                      if (_dragStart != null) {
                        setState(() {
                          _dragCurrent = details.localFocalPoint;
                          if (annoState.activeTool == AnnotationTool.ink) {
                            _activeInkPoints.add(DrawingPoint(
                              details.localFocalPoint.dx / scale,
                              details.localFocalPoint.dy / scale,
                            ));
                          }
                        });
                      }
                    },
                    onScaleEnd: (details) {
                      if (details.pointerCount >= 2) return;
                      if (_dragStart != null && _dragCurrent != null) {
                        _finishAnnotation(pageNum, scale, annoState, docState);
                      }
                      setState(() {
                        _dragStart = null;
                        _dragCurrent = null;
                        _activeInkPoints.clear();
                      });
                    },
                    child: CustomPaint(
                      painter: _ActiveDrawingPainter(
                        tool: annoState.activeTool,
                        start: _dragStart,
                        current: _dragCurrent,
                        inkPoints: _activeInkPoints,
                        color: annoState.selectedColor,
                        strokeWidth: annoState.strokeWidth,
                        scale: scale,
                      ),
                    ),
                  ),
                ),

              // 5. Quick Copy Page Floating Action
              Positioned(
                top: 8,
                right: 8,
                child: _buildCopyPageBadge(pageNum, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableTextLayer({
    required int pageNum,
    required Size pageSize,
    required double scale,
    required ThemeData theme,
    required DocumentState docState,
  }) {
    final cachedLines = _pageLinesCache[pageNum];
    final cachedText = _pageTextCache[pageNum];

    if (cachedLines == null && cachedText == null) {
      return FutureBuilder<List<PdfTextLine>>(
        future: docState.engine.extractPageLines(pageNum),
        builder: (context, snapshot) {
          final lines = snapshot.data ?? [];
          if (lines.isNotEmpty) {
            _pageLinesCache[pageNum] = lines;
            _pageTextCache[pageNum] = lines.map((l) => l.text).join('\n').trim();
          }
          return _buildTextSelectionWidget(
            pageNum: pageNum,
            pageSize: pageSize,
            scale: scale,
            theme: theme,
            lines: lines,
            pageText: _pageTextCache[pageNum] ?? '',
          );
        },
      );
    }

    return _buildTextSelectionWidget(
      pageNum: pageNum,
      pageSize: pageSize,
      scale: scale,
      theme: theme,
      lines: cachedLines ?? [],
      pageText: cachedText ?? '',
    );
  }

  Widget _buildTextSelectionWidget({
    required int pageNum,
    required Size pageSize,
    required double scale,
    required ThemeData theme,
    required List<PdfTextLine> lines,
    required String pageText,
  }) {
    final displayLines = lines.isNotEmpty
        ? lines
        : (pageText.trim().isNotEmpty
            ? pageText.trim().split('\n').map((t) => PdfTextLine(text: t)).toList()
            : <PdfTextLine>[]);

    if (displayLines.isEmpty) {
      return const SizedBox.shrink();
    }

    final fullWidth = pageSize.width * scale;
    final fullHeight = pageSize.height * scale;

    return Theme(
      data: theme.copyWith(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: theme.colorScheme.primary.withValues(alpha: 0.32),
          selectionHandleColor: theme.colorScheme.primary,
        ),
      ),
      child: SelectionArea(
        key: ValueKey('page_selection_${pageNum}_$scale'),
        contextMenuBuilder: (context, selectableRegionState) {
          return _buildTextContextMenu(context, selectableRegionState, pageNum);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.text,
          child: Container(
            width: fullWidth,
            height: fullHeight,
            color: Colors.transparent,
            padding: EdgeInsets.symmetric(
              horizontal: (fullWidth * 0.08).clamp(16.0, 54.0),
              vertical: (fullHeight * 0.05).clamp(16.0, 50.0),
            ),
            child: ClipRect(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: displayLines.map((line) {
                  final text = line.text;
                  final isHeading = (text.length < 45 && text == text.toUpperCase() && RegExp(r'[A-Z]').hasMatch(text)) || line.fontSize >= 18;
                  final effectiveFontSize = isHeading
                      ? (line.fontSize * 0.9 * scale).clamp(12.0, 36.0)
                      : (line.fontSize * 0.95 * scale).clamp(9.0, 24.0);

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: (isHeading ? 8.0 : 4.0) * scale,
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: effectiveFontSize,
                        fontWeight: isHeading ? FontWeight.bold : FontWeight.normal,
                        height: 1.35,
                        color: Colors.transparent,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextContextMenu(
    BuildContext context,
    SelectableRegionState selectableRegionState,
    int pageNum,
  ) {
    final buttonItems = <ContextMenuButtonItem>[
      ContextMenuButtonItem(
        type: ContextMenuButtonType.copy,
        onPressed: () {
          selectableRegionState.copySelection(SelectionChangedCause.toolbar);
          selectableRegionState.hideToolbar();
          _showToast('Copied selection to clipboard');
        },
      ),
      ContextMenuButtonItem(
        type: ContextMenuButtonType.selectAll,
        onPressed: () {
          selectableRegionState.selectAll(SelectionChangedCause.toolbar);
        },
      ),
      ContextMenuButtonItem(
        label: 'Copy Page $pageNum Text',
        onPressed: () {
          selectableRegionState.hideToolbar();
          _copyPageTextToClipboard(pageNum);
        },
      ),
      ContextMenuButtonItem(
        label: 'Highlight Selection',
        onPressed: () {
          selectableRegionState.hideToolbar();
          _highlightSelection(pageNum);
        },
      ),
    ];

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: selectableRegionState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  Widget _buildCopyPageBadge(int pageNum, ThemeData theme) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredPage = pageNum),
      onExit: (_) => setState(() => _hoveredPage = null),
      child: AnimatedOpacity(
        opacity: _hoveredPage == pageNum ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Tooltip(
          message: 'Copy all text on Page $pageNum to clipboard',
          child: Material(
            color: theme.colorScheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            shadowColor: Colors.black26,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _copyPageTextToClipboard(pageNum),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded, size: 13, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Copy Page',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _copyPageTextToClipboard(int pageNum) {
    String textToCopy = _pageTextCache[pageNum]?.trim() ?? '';
    if (textToCopy.isEmpty) {
      final docState = ref.read(documentProvider);
      docState.engine.extractText(pageNum).then((extracted) {
        if (!mounted) return;
        if (extracted.trim().isNotEmpty) {
          _pageTextCache[pageNum] = extracted.trim();
          Clipboard.setData(ClipboardData(text: extracted.trim()));
          final count = extracted.trim().split(RegExp(r'\s+')).length;
          _showToast('Copied Page $pageNum text ($count words) to clipboard');
        } else {
          _showToast('No text found on Page $pageNum');
        }
      });
      return;
    }
    Clipboard.setData(ClipboardData(text: textToCopy));
    final count = textToCopy.split(RegExp(r'\s+')).length;
    _showToast('Copied Page $pageNum text ($count words) to clipboard');
  }

  void _highlightSelection(int pageNum) {
    final docState = ref.read(documentProvider);
    final docPath = docState.currentPath ?? 'sample.pdf';
    final annoState = ref.read(annotationProvider);

    final highlightAnno = AnnotationModel(
      id: const Uuid().v4(),
      documentPath: docPath,
      pageNumber: pageNum,
      type: AnnotationType.highlight,
      color: annoState.selectedColor != Colors.transparent ? annoState.selectedColor : Colors.amber,
      opacity: 0.45,
      rect: const Rect.fromLTWH(40, 60, 400, 28),
    );
    ref.read(annotationProvider.notifier).addAnnotation(highlightAnno);
    _showToast('Added highlight annotation to Page $pageNum');
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(child: Text(message, overflow: TextOverflow.ellipsis)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _finishAnnotation(
    int pageNum,
    double scale,
    AnnotationState annoState,
    DocumentState docState,
  ) {
    if (_dragStart == null || _dragCurrent == null) return;

    final docPath = docState.currentPath ?? 'sample.pdf';
    final p1 = Offset(_dragStart!.dx / scale, _dragStart!.dy / scale);
    final p2 = Offset(_dragCurrent!.dx / scale, _dragCurrent!.dy / scale);
    final rect = Rect.fromPoints(p1, p2);

    AnnotationModel? newAnno;

    switch (annoState.activeTool) {
      case AnnotationTool.highlight:
        newAnno = AnnotationModel(
          id: const Uuid().v4(),
          documentPath: docPath,
          pageNumber: pageNum,
          type: AnnotationType.highlight,
          color: annoState.selectedColor,
          opacity: 0.45,
          rect: rect,
        );
        break;

      case AnnotationTool.underline:
        newAnno = AnnotationModel(
          id: const Uuid().v4(),
          documentPath: docPath,
          pageNumber: pageNum,
          type: AnnotationType.underline,
          color: annoState.selectedColor,
          strokeWidth: annoState.strokeWidth,
          rect: rect,
        );
        break;

      case AnnotationTool.strikethrough:
        newAnno = AnnotationModel(
          id: const Uuid().v4(),
          documentPath: docPath,
          pageNumber: pageNum,
          type: AnnotationType.strikethrough,
          color: annoState.selectedColor,
          strokeWidth: annoState.strokeWidth,
          rect: rect,
        );
        break;

      case AnnotationTool.textBox:
        newAnno = AnnotationModel(
          id: const Uuid().v4(),
          documentPath: docPath,
          pageNumber: pageNum,
          type: AnnotationType.textBox,
          color: annoState.selectedColor,
          rect: rect,
          text: 'Type text here...',
        );
        break;

      case AnnotationTool.stickyNote:
        newAnno = AnnotationModel(
          id: const Uuid().v4(),
          documentPath: docPath,
          pageNumber: pageNum,
          type: AnnotationType.stickyNote,
          color: Colors.amber,
          rect: Rect.fromLTWH(p1.dx, p1.dy, 32, 32),
          text: 'Comment note...',
        );
        break;

      case AnnotationTool.ink:
        newAnno = AnnotationModel(
          id: const Uuid().v4(),
          documentPath: docPath,
          pageNumber: pageNum,
          type: AnnotationType.ink,
          color: annoState.selectedColor,
          strokeWidth: annoState.strokeWidth,
          rect: rect,
          points: List.from(_activeInkPoints),
        );
        break;

      case AnnotationTool.rectangle:
        newAnno = AnnotationModel(
          id: const Uuid().v4(),
          documentPath: docPath,
          pageNumber: pageNum,
          type: AnnotationType.rectangle,
          color: annoState.selectedColor,
          strokeWidth: annoState.strokeWidth,
          rect: rect,
        );
        break;

      case AnnotationTool.circle:
        newAnno = AnnotationModel(
          id: const Uuid().v4(),
          documentPath: docPath,
          pageNumber: pageNum,
          type: AnnotationType.circle,
          color: annoState.selectedColor,
          strokeWidth: annoState.strokeWidth,
          rect: rect,
        );
        break;

      case AnnotationTool.arrow:
        newAnno = AnnotationModel(
          id: const Uuid().v4(),
          documentPath: docPath,
          pageNumber: pageNum,
          type: AnnotationType.arrow,
          color: annoState.selectedColor,
          strokeWidth: annoState.strokeWidth,
          rect: rect,
        );
        break;

      case AnnotationTool.stamp:
        newAnno = AnnotationModel(
          id: const Uuid().v4(),
          documentPath: docPath,
          pageNumber: pageNum,
          type: AnnotationType.stamp,
          color: Colors.red,
          rect: Rect.fromLTWH(p1.dx, p1.dy, 120, 40),
          text: 'APPROVED',
        );
        break;

      default:
        break;
    }

    if (newAnno != null) {
      ref.read(annotationProvider.notifier).addAnnotation(newAnno);
    }
  }

  Future<Uint8List?> _renderPage(
    DocumentState docState,
    int pageNum,
    double width,
    double height,
    double dpr,
    double upscaleFactor,
  ) async {
    // Preserve exact page aspect ratio
    if (!_pageDimensionsCache.containsKey(pageNum)) {
      final size = await docState.engine.getPageDimensions(pageNum);
      _pageDimensionsCache[pageNum] = size;
      if (mounted) {
        setState(() {});
      }
    }
    final pageSize = _pageDimensionsCache[pageNum] ?? const Size(595.0, 842.0);
    final aspect = (pageSize.width > 0 && pageSize.height > 0)
        ? (pageSize.width / pageSize.height)
        : (595.0 / 842.0);

    // Dynamic High-Resolution Supersampling with Upscale Option:
    // Ensures text and vector graphics are crystal-clear and razor-sharp at any zoom level
    final effectiveDpr = math.max(2.0, dpr);
    final calculatedWidth = (width * effectiveDpr * upscaleFactor).round();
    final minResolution = (1800 * upscaleFactor).round();
    final maxResolution = (4800 * math.min(upscaleFactor, 2.0)).clamp(4096, 7200).toInt();
    final renderWidth = calculatedWidth.clamp(minResolution, maxResolution);

    // Discrete resolution buckets (multiples of 64) to maximize cache hits and eliminate jitter
    final bucketedWidth = ((renderWidth + 63) ~/ 64) * 64;
    final bucketedHeight = (bucketedWidth / aspect).round();

    final key = pageNum * 100000 + bucketedWidth;
    if (_pageRenderCache.containsKey(key) && _pageRenderCache[key] != null) {
      return _pageRenderCache[key];
    }
    final bytes = await docState.engine.renderPageThumbnail(
      pageNum,
      width: bucketedWidth,
      height: bucketedHeight,
    );
    if (bytes != null) {
      if (_pageRenderCache.length > 60) {
        _pageRenderCache.clear();
      }
      _pageRenderCache[key] = bytes;
      _lastRenderedPage[pageNum] = bytes;
    }
    return bytes;
  }
}

class _AnnotationsPainter extends CustomPainter {
  final List<AnnotationModel> annotations;
  final double scale;
  final String? selectedId;

  _AnnotationsPainter({
    required this.annotations,
    required this.scale,
    this.selectedId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final a in annotations) {
      final isSelected = a.id == selectedId;
      final scaledRect = Rect.fromLTRB(
        a.rect.left * scale,
        a.rect.top * scale,
        a.rect.right * scale,
        a.rect.bottom * scale,
      );

      switch (a.type) {
        case AnnotationType.highlight:
          final paint = Paint()
            ..color = a.color.withValues(alpha: 0.40)
            ..style = PaintingStyle.fill;
          canvas.drawRect(scaledRect, paint);
          break;

        case AnnotationType.underline:
          final paint = Paint()
            ..color = a.color
            ..strokeWidth = a.strokeWidth * scale;
          canvas.drawLine(scaledRect.bottomLeft, scaledRect.bottomRight, paint);
          break;

        case AnnotationType.strikethrough:
          final paint = Paint()
            ..color = a.color
            ..strokeWidth = a.strokeWidth * scale;
          final midY = (scaledRect.top + scaledRect.bottom) / 2;
          canvas.drawLine(Offset(scaledRect.left, midY), Offset(scaledRect.right, midY), paint);
          break;

        case AnnotationType.rectangle:
          final paint = Paint()
            ..color = a.color
            ..strokeWidth = a.strokeWidth * scale
            ..style = PaintingStyle.stroke;
          canvas.drawRect(scaledRect, paint);
          break;

        case AnnotationType.circle:
          final paint = Paint()
            ..color = a.color
            ..strokeWidth = a.strokeWidth * scale
            ..style = PaintingStyle.stroke;
          canvas.drawOval(scaledRect, paint);
          break;

        case AnnotationType.arrow:
          final paint = Paint()
            ..color = a.color
            ..strokeWidth = a.strokeWidth * scale
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(scaledRect.topLeft, scaledRect.bottomRight, paint);
          break;

        case AnnotationType.ink:
          final paint = Paint()
            ..color = a.color
            ..strokeWidth = a.strokeWidth * scale
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;
          for (int i = 0; i < a.points.length - 1; i++) {
            final p1 = Offset(a.points[i].x * scale, a.points[i].y * scale);
            final p2 = Offset(a.points[i + 1].x * scale, a.points[i + 1].y * scale);
            if ((p1 - p2).distance < 40 * scale) {
              canvas.drawLine(p1, p2, paint);
            }
          }
          break;

        case AnnotationType.stamp:
          final borderPaint = Paint()
            ..color = Colors.red
            ..strokeWidth = 2 * scale
            ..style = PaintingStyle.stroke;
          final rRect = RRect.fromRectAndRadius(scaledRect, Radius.circular(4 * scale));
          canvas.drawRRect(rRect, borderPaint);
          final textPainter = TextPainter(
            text: TextSpan(
              text: a.text.isEmpty ? 'APPROVED' : a.text,
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12 * scale,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          textPainter.paint(
            canvas,
            Offset(
              scaledRect.left + (scaledRect.width - textPainter.width) / 2,
              scaledRect.top + (scaledRect.height - textPainter.height) / 2,
            ),
          );
          break;

        case AnnotationType.stickyNote:
          final notePaint = Paint()..color = Colors.amber.shade300;
          canvas.drawCircle(scaledRect.center, 12 * scale, notePaint);
          final iconPainter = TextPainter(
            text: TextSpan(
              text: String.fromCharCode(Icons.chat_bubble_outline.codePoint),
              style: TextStyle(
                fontFamily: Icons.chat_bubble_outline.fontFamily,
                package: Icons.chat_bubble_outline.fontPackage,
                fontSize: 14 * scale,
                color: Colors.brown.shade800,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          iconPainter.paint(canvas, scaledRect.center - Offset(iconPainter.width / 2, iconPainter.height / 2));
          break;

        case AnnotationType.textBox:
          final boxPaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill;
          canvas.drawRect(scaledRect, boxPaint);
          final border = Paint()
            ..color = a.color
            ..strokeWidth = 1 * scale
            ..style = PaintingStyle.stroke;
          canvas.drawRect(scaledRect, border);
          final textPainter = TextPainter(
            text: TextSpan(
              text: a.text,
              style: TextStyle(color: a.color, fontSize: 11 * scale),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: scaledRect.width);
          textPainter.paint(canvas, scaledRect.topLeft + Offset(4 * scale, 4 * scale));
          break;

        default:
          break;
      }

      if (isSelected) {
        final selectPaint = Paint()
          ..color = Colors.blue
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawRect(scaledRect.inflate(4), selectPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationsPainter oldDelegate) => true;
}

class _ActiveDrawingPainter extends CustomPainter {
  final AnnotationTool tool;
  final Offset? start;
  final Offset? current;
  final List<DrawingPoint> inkPoints;
  final Color color;
  final double strokeWidth;
  final double scale;

  _ActiveDrawingPainter({
    required this.tool,
    this.start,
    this.current,
    required this.inkPoints,
    required this.color,
    required this.strokeWidth,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (start == null || current == null) return;

    final rect = Rect.fromPoints(start!, current!);

    if (tool == AnnotationTool.highlight) {
      final paint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);
    } else if (tool == AnnotationTool.underline) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth;
      canvas.drawLine(rect.bottomLeft, rect.bottomRight, paint);
    } else if (tool == AnnotationTool.strikethrough) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth;
      final midY = (rect.top + rect.bottom) / 2;
      canvas.drawLine(Offset(rect.left, midY), Offset(rect.right, midY), paint);
    } else if (tool == AnnotationTool.rectangle) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawRect(rect, paint);
    } else if (tool == AnnotationTool.circle) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawOval(rect, paint);
    } else if (tool == AnnotationTool.arrow) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start!, current!, paint);
    } else if (tool == AnnotationTool.ink && inkPoints.isNotEmpty) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (int i = 0; i < inkPoints.length - 1; i++) {
        final p1 = Offset(inkPoints[i].x * scale, inkPoints[i].y * scale);
        final p2 = Offset(inkPoints[i + 1].x * scale, inkPoints[i + 1].y * scale);
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ActiveDrawingPainter oldDelegate) => true;
}
