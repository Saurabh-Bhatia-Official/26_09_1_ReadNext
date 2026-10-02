import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../state/annotation_provider.dart';
import '../../../state/document_provider.dart';
import '../../../state/settings_provider.dart';
import '../dialogs/signature_pad_dialog.dart';

class AnnotationRibbon extends ConsumerWidget {
  const AnnotationRibbon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final annoState = ref.watch(annotationProvider);
    final docState = ref.watch(documentProvider);
    final theme = Theme.of(context);

    if (!settings.isAnnotationRibbonOpen || !docState.hasDocument) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerTheme.color ?? Colors.grey.shade300),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Select Tool
            _toolBtn(ref, AnnotationTool.select, Icons.pan_tool_outlined, 'Select / Hand'),

            const VerticalDivider(width: 12, indent: 8, endIndent: 8),

            // Markup Tools
            _toolBtn(ref, AnnotationTool.highlight, Icons.highlight_outlined, 'Highlight'),
            _toolBtn(ref, AnnotationTool.underline, Icons.format_underlined, 'Underline'),
            _toolBtn(ref, AnnotationTool.strikethrough, Icons.format_strikethrough, 'Strikethrough'),
            _toolBtn(ref, AnnotationTool.textBox, Icons.text_fields, 'Text Box'),
            _toolBtn(ref, AnnotationTool.ink, Icons.edit, 'Freehand Pen'),
            _toolBtn(ref, AnnotationTool.stickyNote, Icons.note_outlined, 'Sticky Note'),

            const VerticalDivider(width: 12, indent: 8, endIndent: 8),

            // Shapes & Stamps
            _toolBtn(ref, AnnotationTool.rectangle, Icons.crop_square, 'Rectangle'),
            _toolBtn(ref, AnnotationTool.circle, Icons.radio_button_unchecked, 'Circle'),
            _toolBtn(ref, AnnotationTool.arrow, Icons.arrow_forward, 'Arrow'),
            _toolBtn(ref, AnnotationTool.stamp, Icons.approval, 'Stamp'),

            // Digital Signature Pad Trigger
            IconButton(
              icon: Icon(
                Icons.draw_outlined,
                size: 19,
                color: annoState.activeTool == AnnotationTool.signature
                    ? theme.colorScheme.primary
                    : null,
              ),
              tooltip: 'Digital Signature',
              onPressed: () async {
                final points = await SignaturePadDialog.show(context);
                if (points != null && points.isNotEmpty) {
                  ref.read(annotationProvider.notifier).setTool(AnnotationTool.signature);
                }
              },
            ),

            const VerticalDivider(width: 12, indent: 8, endIndent: 8),

            // Color Palette Chips
            ...AppConstants.highlightColors.take(4).map((c) {
              final isSelected = annoState.selectedColor == c;
              return GestureDetector(
                onTap: () => ref.read(annotationProvider.notifier).setColor(c),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                ),
              );
            }),

            const VerticalDivider(width: 12, indent: 8, endIndent: 8),

            // Undo / Redo Buttons
            IconButton(
              icon: const Icon(Icons.undo, size: 18),
              tooltip: 'Undo (Ctrl+Z)',
              onPressed: annoState.canUndo
                  ? () => ref.read(annotationProvider.notifier).undo()
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.redo, size: 18),
              tooltip: 'Redo (Ctrl+Y)',
              onPressed: annoState.canRedo
                  ? () => ref.read(annotationProvider.notifier).redo()
                  : null,
            ),

            // Close Ribbon
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Close Ribbon',
              onPressed: () => ref.read(settingsProvider.notifier).toggleAnnotationRibbon(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolBtn(WidgetRef ref, AnnotationTool tool, IconData icon, String tooltip) {
    final activeTool = ref.watch(annotationProvider).activeTool;
    final isSelected = activeTool == tool;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 19),
        color: isSelected ? Colors.white : null,
        style: isSelected
            ? IconButton.styleFrom(backgroundColor: const Color(0xFF0D47A1))
            : null,
        onPressed: () => ref.read(annotationProvider.notifier).setTool(tool),
      ),
    );
  }
}
