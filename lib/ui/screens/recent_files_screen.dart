import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/recent_document.dart';
import '../../../state/document_provider.dart';
import '../../../state/settings_provider.dart';

class RecentFilesScreen extends ConsumerStatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;
  const RecentFilesScreen({super.key, this.onNavigateTab});

  @override
  ConsumerState<RecentFilesScreen> createState() => _RecentFilesScreenState();
}

class _RecentFilesScreenState extends ConsumerState<RecentFilesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFavoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    final query = _searchController.text.trim().toLowerCase();
    final filtered = settingsState.recentDocuments.where((doc) {
      if (_showFavoritesOnly && !doc.isFavorite) return false;
      if (query.isNotEmpty) {
        return doc.title.toLowerCase().contains(query) || doc.path.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Documents'),
        actions: [
          FilterChip(
            label: const Text('Favorites Only'),
            selected: _showFavoritesOnly,
            onSelected: (val) => setState(() => _showFavoritesOnly = val),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search recent documents by filename or path...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchController.clear()),
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open, size: 56, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(
                            _searchController.text.isNotEmpty ? 'No documents match your query' : 'No recent documents found',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        return _buildRecentCard(context, doc);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCard(BuildContext context, RecentDocument doc) {
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
        title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '$sizeStr • ${doc.pageCount} pages • Last opened: $timeStr\n${doc.path}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                doc.isFavorite ? Icons.star : Icons.star_border,
                color: doc.isFavorite ? Colors.amber : null,
              ),
              onPressed: () => ref.read(settingsProvider.notifier).toggleFavorite(doc.path),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
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
