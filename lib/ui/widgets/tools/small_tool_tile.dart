import 'package:flutter/material.dart';
import 'tools_catalog.dart';

class SmallToolTile extends StatefulWidget {
  final ToolItem tool;
  final void Function(int tabIndex)? onNavigateTab;
  final VoidCallback? onBeforeOpen;

  const SmallToolTile({
    super.key,
    required this.tool,
    this.onNavigateTab,
    this.onBeforeOpen,
  });

  @override
  State<SmallToolTile> createState() => _SmallToolTileState();
}

class _SmallToolTileState extends State<SmallToolTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = widget.tool;

    return Tooltip(
      message: '${t.title}\n${t.description}',
      waitDuration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      textStyle: const TextStyle(fontSize: 12, color: Colors.white),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: isDark
                ? (_isHovered ? theme.cardColor : theme.colorScheme.surface)
                : (_isHovered ? Colors.white : theme.cardColor),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? t.color.withValues(alpha: 0.7)
                  : theme.dividerColor.withValues(alpha: isDark ? 0.3 : 0.6),
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? t.color.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: _isHovered ? 10 : 3,
                offset: Offset(0, _isHovered ? 4 : 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                widget.onBeforeOpen?.call();
                t.onOpen(context, onNavigateTab: widget.onNavigateTab);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon Badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: t.color.withValues(alpha: _isHovered ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        t.icon,
                        color: t.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      t.title,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isHovered ? t.color : theme.textTheme.bodyMedium?.color,
                        height: 1.2,
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
}
