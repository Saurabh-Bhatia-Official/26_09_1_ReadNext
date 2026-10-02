import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/recent_document.dart';
import '../../../services/file_service.dart';
import '../../../state/document_provider.dart';
import '../../../state/settings_provider.dart';
import '../widgets/tools/compress_tool_view.dart';
import '../widgets/tools/converter_tool_view.dart';
import '../widgets/tools/merge_tool_view.dart';
import '../widgets/tools/ocr_tool_view.dart';
import '../widgets/tools/split_tool_view.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;
  const HomeDashboardScreen({super.key, this.onNavigateTab});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = ref.watch(settingsProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        if (details.files.isNotEmpty) {
          final path = details.files.first.path;
          if (path.toLowerCase().endsWith('.pdf')) {
            await ref.read(documentProvider.notifier).openFile(path);
            widget.onNavigateTab?.call(2); // Switch to Viewer
          }
        }
      },
      child: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 18 : 28),
                decoration: BoxDecoration(
                  gradient: settingsState.themeMode == AppThemeMode.corporate
                      ? const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF0D2556)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF002171)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: settingsState.themeMode == AppThemeMode.corporate
                      ? Border.all(color: const Color(0xFF243B5C), width: 1.2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, heroConstraints) {
                    final isNarrow = heroConstraints.maxWidth < 650;
                    return Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                AppConstants.appLogoIcon,
                                width: 56,
                                height: 56,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 16),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: (heroConstraints.maxWidth - (isNarrow ? 80 : 260)).clamp(150.0, 600.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 10,
                                    children: [
                                      Text(
                                        AppConstants.appName,
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppConstants.appTagline,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Developed by ${AppConstants.developerName} • 100% Offline & Local Processing',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue.shade900,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Open PDF File', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final path = await FileService.pickPdfFile();
                            if (path != null) {
                              await ref.read(documentProvider.notifier).openFile(path);
                              widget.onNavigateTab?.call(2); // Viewer
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Drag & Drop Intake Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: BoxDecoration(
                  color: _isDragging ? theme.colorScheme.primary.withValues(alpha: 0.08) : theme.cardColor,
                  border: Border.all(
                    color: _isDragging ? theme.colorScheme.primary : theme.dividerColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.file_upload_outlined, size: 26, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Drag and drop PDF files anywhere here to open instantly',
                        style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Quick Actions Section (PRD Section 6.1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Quick Actions',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.apps, size: 18),
                    label: const Text('View All Tools'),
                    onPressed: () => widget.onNavigateTab?.call(1),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Grid of 8 PRD Quick Actions
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisExtent: 106,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                children: [
                  _buildToolTile(
                    title: 'Merge PDF',
                    subtitle: 'Combine multiple PDFs into one',
                    icon: Icons.call_merge,
                    color: const Color(0xFF1E88E5),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MergeToolView())),
                  ),
                  _buildToolTile(
                    title: 'Split PDF',
                    subtitle: 'Split by pages or ranges',
                    icon: Icons.call_split,
                    color: const Color(0xFF43A047),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SplitToolView())),
                  ),
                  _buildToolTile(
                    title: 'Compress PDF',
                    subtitle: 'Reduce document file size',
                    icon: Icons.compress,
                    color: const Color(0xFF00ACC1),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompressToolView())),
                  ),
                  _buildToolTile(
                    title: 'Convert PDF',
                    subtitle: 'PDF to Word, Excel & PPT',
                    icon: Icons.sync_alt,
                    color: const Color(0xFF8E24AA),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConverterToolView(initialTabIndex: 2))),
                  ),
                  _buildToolTile(
                    title: 'Edit PDF',
                    subtitle: 'Annotations, drawings & forms',
                    icon: Icons.edit_note,
                    color: const Color(0xFFFB8C00),
                    onTap: () => widget.onNavigateTab?.call(2), // Viewer
                  ),
                  _buildToolTile(
                    title: 'OCR Text',
                    subtitle: 'Extract text from scanned PDFs',
                    icon: Icons.document_scanner,
                    color: const Color(0xFFD81B60),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OcrToolView())),
                  ),
                  _buildToolTile(
                    title: 'PDF to Image',
                    subtitle: 'Extract PNG, JPG, or WEBP',
                    icon: Icons.photo_library_outlined,
                    color: const Color(0xFF5E35B1),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConverterToolView(initialTabIndex: 0))),
                  ),
                  _buildToolTile(
                    title: 'Image to PDF',
                    subtitle: 'Create PDF from image files',
                    icon: Icons.add_photo_alternate_outlined,
                    color: const Color(0xFF3949AB),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConverterToolView(initialTabIndex: 1))),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Recent Files Section (PRD Section 6.1 & 23)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Recent Documents',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (settingsState.recentDocuments.isNotEmpty)
                    TextButton(
                      child: const Text('View All'),
                      onPressed: () => widget.onNavigateTab?.call(4), // Recent tab
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (settingsState.recentDocuments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 42, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        const Text('No recent documents yet', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Opened and processed files will appear here for fast access.',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                )
              else
                ...settingsState.recentDocuments.take(5).map((doc) => _buildRecentFileCard(context, doc)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentFileCard(BuildContext context, RecentDocument doc) {
    final theme = Theme.of(context);
    final sizeStr = Formatters.formatFileSize(doc.fileSize);
    final timeStr = Formatters.formatDate(doc.lastOpened);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 22),
        ),
        title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '$sizeStr • ${doc.pageCount} pages • Last opened: $timeStr\n${doc.path}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(doc.isFavorite ? Icons.star : Icons.star_border, color: doc.isFavorite ? Colors.amber : null),
              onPressed: () => ref.read(settingsProvider.notifier).toggleFavorite(doc.path),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => ref.read(settingsProvider.notifier).removeRecentDocument(doc.path),
            ),
          ],
        ),
        onTap: () async {
          await ref.read(documentProvider.notifier).openFile(doc.path);
          widget.onNavigateTab?.call(2); // Viewer
        },
      ),
    );
  }
}
