import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../services/file_service.dart';
import '../../../state/document_provider.dart';
import '../../../state/settings_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return DropTarget(
      onDragEntered: (details) => setState(() => _isDragging = true),
      onDragExited: (details) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        if (details.files.isNotEmpty) {
          final path = details.files.first.path;
          if (path.toLowerCase().endsWith('.pdf')) {
            await ref.read(documentProvider.notifier).openFile(path);
          }
        }
      },
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon & Hero Header
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      AppConstants.appLogoIcon,
                      width: 76,
                      height: 76,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    AppConstants.appTagline,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Dropzone Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                    decoration: BoxDecoration(
                      color: _isDragging
                          ? theme.colorScheme.primary.withValues(alpha: 0.08)
                          : theme.cardTheme.color ?? Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isDragging
                            ? theme.colorScheme.primary
                            : theme.dividerTheme.color ?? Colors.grey.shade300,
                        width: _isDragging ? 2.5 : 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _isDragging ? Icons.file_download : Icons.cloud_upload_outlined,
                          size: 48,
                          color: _isDragging ? theme.colorScheme.primary : Colors.grey.shade500,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _isDragging ? 'Drop PDF here to open' : 'Drag & Drop PDF file here',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'or choose from local storage or bundled demonstration files',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            FilledButton.icon(
                              onPressed: () async {
                                final path = await FileService.pickPdfFile();
                                if (path != null) {
                                  await ref.read(documentProvider.notifier).openFile(path);
                                }
                              },
                              icon: const Icon(Icons.folder_open, size: 18),
                              label: const Text('Open PDF File (Ctrl+O)'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await ref.read(documentProvider.notifier).openSample();
                              },
                              icon: const Icon(Icons.description_outlined, size: 18),
                              label: const Text('Open Sample Specification PDF'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Recent Documents Section
                  if (settings.recentDocuments.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Icon(Icons.history, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Recent Documents',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: settings.recentDocuments.length.clamp(0, 5),
                      itemBuilder: (context, index) {
                        final doc = settings.recentDocuments[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE3F2FD),
                              child: Icon(Icons.picture_as_pdf, color: Color(0xFF1565C0), size: 20),
                            ),
                            title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('${Formatters.formatBytes(doc.fileSize)} • ${doc.pageCount} pages',
                                        style: const TextStyle(fontSize: 11)),
                                    const Spacer(),
                                    Text('Last opened ${Formatters.formatDateShort(doc.lastOpened)}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: doc.progress,
                                  minHeight: 3,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    doc.isFavorite ? Icons.star : Icons.star_border,
                                    color: doc.isFavorite ? Colors.amber : null,
                                    size: 18,
                                  ),
                                  onPressed: () => ref.read(settingsProvider.notifier).toggleFavorite(doc.path),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  onPressed: () => ref.read(settingsProvider.notifier).removeRecentDocument(doc.path),
                                ),
                              ],
                            ),
                            onTap: () async {
                              await ref.read(documentProvider.notifier).openFile(doc.path);
                            },
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Shortcuts Footer
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _shortcutBadge('Ctrl + O', 'Open File'),
                      _shortcutBadge('Ctrl + S', 'Save / Export'),
                      _shortcutBadge('Ctrl + P', 'Print'),
                      _shortcutBadge('Ctrl + F', 'Search'),
                      _shortcutBadge('Ctrl + Z', 'Undo'),
                      _shortcutBadge('F5', 'Presentation'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _shortcutBadge(String keys, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$keys: $label',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
