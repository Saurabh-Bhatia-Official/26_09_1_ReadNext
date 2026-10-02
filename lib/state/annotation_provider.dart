import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/database/app_database.dart';
import '../../data/models/annotation_model.dart';

enum AnnotationTool {
  select,
  highlight,
  underline,
  strikethrough,
  textBox,
  ink,
  stickyNote,
  rectangle,
  circle,
  line,
  arrow,
  signature,
  stamp,
}

class AnnotationState {
  final AnnotationTool activeTool;
  final Color selectedColor;
  final double strokeWidth;
  final double opacity;
  final List<AnnotationModel> annotations;
  final AnnotationModel? selectedAnnotation;
  final List<List<AnnotationModel>> undoStack;
  final List<List<AnnotationModel>> redoStack;

  const AnnotationState({
    this.activeTool = AnnotationTool.select,
    this.selectedColor = const Color(0xFFFFEB3B),
    this.strokeWidth = 3.0,
    this.opacity = 1.0,
    this.annotations = const [],
    this.selectedAnnotation,
    this.undoStack = const [],
    this.redoStack = const [],
  });

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  List<AnnotationModel> getAnnotationsForPage(int page) {
    return annotations.where((a) => a.pageNumber == page).toList();
  }

  AnnotationState copyWith({
    AnnotationTool? activeTool,
    Color? selectedColor,
    double? strokeWidth,
    double? opacity,
    List<AnnotationModel>? annotations,
    AnnotationModel? selectedAnnotation,
    bool clearSelected = false,
    List<List<AnnotationModel>>? undoStack,
    List<List<AnnotationModel>>? redoStack,
  }) {
    return AnnotationState(
      activeTool: activeTool ?? this.activeTool,
      selectedColor: selectedColor ?? this.selectedColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      annotations: annotations ?? this.annotations,
      selectedAnnotation: clearSelected ? null : (selectedAnnotation ?? this.selectedAnnotation),
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
    );
  }
}

class AnnotationNotifier extends Notifier<AnnotationState> {
  @override
  AnnotationState build() {
    return const AnnotationState();
  }

  void setTool(AnnotationTool tool) {
    Color defaultColor = state.selectedColor;
    double defaultWidth = state.strokeWidth;
    double defaultOpacity = state.opacity;

    switch (tool) {
      case AnnotationTool.highlight:
        defaultColor = AppConstants.highlightColors.first;
        defaultOpacity = 0.45;
        break;
      case AnnotationTool.underline:
      case AnnotationTool.strikethrough:
        defaultColor = Colors.red;
        defaultWidth = 2.0;
        defaultOpacity = 1.0;
        break;
      case AnnotationTool.ink:
        defaultColor = Colors.black;
        defaultWidth = 3.0;
        defaultOpacity = 1.0;
        break;
      case AnnotationTool.stickyNote:
        defaultColor = Colors.amber;
        break;
      case AnnotationTool.stamp:
        defaultColor = Colors.red;
        break;
      default:
        break;
    }

    state = state.copyWith(
      activeTool: tool,
      selectedColor: defaultColor,
      strokeWidth: defaultWidth,
      opacity: defaultOpacity,
      clearSelected: true,
    );
  }

  void setColor(Color color) {
    state = state.copyWith(selectedColor: color);
    if (state.selectedAnnotation != null) {
      updateAnnotation(state.selectedAnnotation!.copyWith(color: color));
    }
  }

  void setStrokeWidth(double width) {
    state = state.copyWith(strokeWidth: width);
    if (state.selectedAnnotation != null) {
      updateAnnotation(state.selectedAnnotation!.copyWith(strokeWidth: width));
    }
  }

  void setOpacity(double opacity) {
    state = state.copyWith(opacity: opacity);
    if (state.selectedAnnotation != null) {
      updateAnnotation(state.selectedAnnotation!.copyWith(opacity: opacity));
    }
  }

  void selectAnnotation(AnnotationModel? anno) {
    state = state.copyWith(
      selectedAnnotation: anno,
      clearSelected: anno == null,
    );
  }

  Future<void> loadAnnotationsForDocument(String docPath) async {
    final list = await AppDatabase.instance.getAnnotationsForDocument(docPath);
    state = state.copyWith(
      annotations: list,
      undoStack: [],
      redoStack: [],
      clearSelected: true,
    );
  }

  void addAnnotation(AnnotationModel annotation) {
    _pushUndoSnapshot();
    final updated = [...state.annotations, annotation];
    state = state.copyWith(annotations: updated);
    AppDatabase.instance.saveAnnotation(annotation);
  }

  void updateAnnotation(AnnotationModel updated) {
    _pushUndoSnapshot();
    final list = state.annotations.map((a) => a.id == updated.id ? updated : a).toList();
    state = state.copyWith(
      annotations: list,
      selectedAnnotation: state.selectedAnnotation?.id == updated.id ? updated : state.selectedAnnotation,
    );
    AppDatabase.instance.saveAnnotation(updated);
  }

  void deleteAnnotation(String id) {
    _pushUndoSnapshot();
    final list = state.annotations.where((a) => a.id != id).toList();
    state = state.copyWith(
      annotations: list,
      clearSelected: state.selectedAnnotation?.id == id,
    );
    AppDatabase.instance.deleteAnnotation(id);
  }

  void clearAllAnnotations(String docPath) {
    _pushUndoSnapshot();
    state = state.copyWith(annotations: [], clearSelected: true);
    AppDatabase.instance.clearAnnotationsForDocument(docPath);
  }

  void undo() {
    if (!state.canUndo) return;
    final previousList = state.undoStack.last;
    final newUndoStack = List<List<AnnotationModel>>.from(state.undoStack)..removeLast();
    final newRedoStack = List<List<AnnotationModel>>.from(state.redoStack)..add(state.annotations);

    state = state.copyWith(
      annotations: previousList,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
      clearSelected: true,
    );
  }

  void redo() {
    if (!state.canRedo) return;
    final nextList = state.redoStack.last;
    final newRedoStack = List<List<AnnotationModel>>.from(state.redoStack)..removeLast();
    final newUndoStack = List<List<AnnotationModel>>.from(state.undoStack)..add(state.annotations);

    state = state.copyWith(
      annotations: nextList,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
      clearSelected: true,
    );
  }

  void _pushUndoSnapshot() {
    final newUndo = List<List<AnnotationModel>>.from(state.undoStack)..add(state.annotations);
    if (newUndo.length > 30) {
      newUndo.removeAt(0);
    }
    state = state.copyWith(
      undoStack: newUndo,
      redoStack: [],
    );
  }
}

final annotationProvider = NotifierProvider<AnnotationNotifier, AnnotationState>(AnnotationNotifier.new);
