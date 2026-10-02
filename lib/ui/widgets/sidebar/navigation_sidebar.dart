import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/annotation_provider.dart';
import '../../../state/bookmark_provider.dart';
import '../../../state/document_provider.dart';
import '../../../state/navigation_provider.dart';
import '../../../state/search_provider.dart';
import '../../../state/settings_provider.dart';

class NavigationSidebar extends ConsumerStatefulWidget {
  const NavigationSidebar({super.key});

  @override
  ConsumerState<NavigationSidebar> createState() => _NavigationSidebarState();
}

class _NavigationSidebarState extends ConsumerState<NavigationSidebar> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, Uint8List?> _thumbnailCache = {};
  String? _cachedDocId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final docState = ref.watch(documentProvider);
    final navState = ref.watch(navigationProvider);
    final theme = Theme.of(context);

    final currentDocId = '${docState.currentPath ?? ''}_${docState.engine.pageCount}';
    if (_cachedDocId != currentDocId) {
      _thumbnailCache.clear();
      _cachedDocId = currentDocId;
    }

    if (!settingsState.isSidebarOpen || !docState.hasDocument) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final sidebarWidth = isMobile ? (screenWidth * 0.85).clamp(240.0, 300.0) : 300.0;

    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      elevation: isMobile ? 8 : 0,
      child: SizedBox(
        width: sidebarWidth,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: theme.dividerTheme.color ?? Colors.grey.shade300),
            ),
          ),
          child: Column(
            children: [
              // Sidebar Tab Headers
              Container(
                height: 44,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.dividerTheme.color ?? Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _tabIcon(0, Icons.grid_view, 'Thumbnails'),
                    _tabIcon(1, Icons.format_list_bulleted, 'Outline'),
                    _tabIcon(2, Icons.bookmark_border, 'Bookmarks'),
                    _tabIcon(3, Icons.comment_outlined, 'Annotations'),
                    _tabIcon(4, Icons.search, 'Search Results'),
                    if (isMobile)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'Close Sidebar',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => ref.read(settingsProvider.notifier).toggleSidebar(),
                      ),
                  ],
                ),
              ),

              // Active Tab Content
              Expanded(
                child: IndexedStack(
                  index: settingsState.sidebarActiveTab,
                  children: [
                    _buildThumbnailsTab(docState, navState),
                    _buildOutlineTab(),
                    _buildBookmarksTab(docState, navState),
                    _buildAnnotationsTab(navState),
                    _buildSearchTab(docState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _tabIcon(int index, IconData icon, String tooltip) {
    final activeTab = ref.watch(settingsProvider).sidebarActiveTab;
    final isSelected = activeTab == index;
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => ref.read(settingsProvider.notifier).setSidebarTab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  // --- 1. Thumbnails Tab ---
  Widget _buildThumbnailsTab(DocumentState docState, NavigationState navState) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docState.engine.pageCount,
      itemBuilder: (context, index) {
        final pageNum = index + 1;
        final isSelected = navState.currentPage == pageNum;

        return GestureDetector(
          onTap: () {
            ref.read(navigationProvider.notifier).setPage(pageNum);
            if (MediaQuery.of(context).size.width < 700) {
              ref.read(settingsProvider.notifier).toggleSidebar();
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                width: isSelected ? 2.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1 / 1.414, // Standard A4 ratio
                  child: FutureBuilder<Uint8List?>(
                    future: _loadThumbnail(docState, pageNum),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image.memory(snapshot.data!, fit: BoxFit.contain);
                      }
                      return Container(
                        color: Colors.grey.shade100,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Page $pageNum',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List?> _loadThumbnail(DocumentState docState, int pageNum) async {
    if (_thumbnailCache.containsKey(pageNum)) {
      return _thumbnailCache[pageNum];
    }
    final bytes = await docState.engine.renderPageThumbnail(pageNum);
    _thumbnailCache[pageNum] = bytes;
    return bytes;
  }

  // --- 2. Outline Tab ---
  Widget _buildOutlineTab() {
    final bookmarkState = ref.watch(bookmarkProvider);
    if (bookmarkState.outline.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No outline or bookmarks found in this document.', textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.builder(
      itemCount: bookmarkState.outline.length,
      itemBuilder: (context, index) {
        final item = bookmarkState.outline[index];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.bookmark_outline, size: 16),
          title: Text(item.title, style: const TextStyle(fontSize: 12)),
          trailing: Text('${item.pageNumber}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          onTap: () => ref.read(navigationProvider.notifier).setPage(item.pageNumber),
        );
      },
    );
  }

  // --- 3. Bookmarks Tab ---
  Widget _buildBookmarksTab(DocumentState docState, NavigationState navState) {
    final bookmarkState = ref.watch(bookmarkProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: OutlinedButton.icon(
            onPressed: () async {
              final docPath = docState.currentPath ?? 'sample.pdf';
              await ref.read(bookmarkProvider.notifier).addBookmark(
                    docPath,
                    navState.currentPage,
                    'Bookmark: Page ${navState.currentPage}',
                  );
            },
            icon: const Icon(Icons.add, size: 16),
            label: Text('Bookmark Page ${navState.currentPage}'),
          ),
        ),
        const Divider(),
        Expanded(
          child: bookmarkState.bookmarks.isEmpty
              ? const Center(child: Text('No bookmarks added yet.'))
              : ListView.builder(
                  itemCount: bookmarkState.bookmarks.length,
                  itemBuilder: (context, index) {
                    final b = bookmarkState.bookmarks[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.bookmark, color: Colors.amber, size: 18),
                      title: Text(b.title, style: const TextStyle(fontSize: 12)),
                      subtitle: Text('Page ${b.pageNumber}', style: const TextStyle(fontSize: 10)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16),
                        onPressed: () => ref.read(bookmarkProvider.notifier).deleteBookmark(b.id),
                      ),
                      onTap: () => ref.read(navigationProvider.notifier).setPage(b.pageNumber),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- 4. Annotations Tab ---
  Widget _buildAnnotationsTab(NavigationState navState) {
    final annoState = ref.watch(annotationProvider);
    if (annoState.annotations.isEmpty) {
      return const Center(child: Text('No annotations added yet.'));
    }

    return ListView.builder(
      itemCount: annoState.annotations.length,
      itemBuilder: (context, index) {
        final anno = annoState.annotations[index];
        return ListTile(
          dense: true,
          leading: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: anno.color, shape: BoxShape.circle),
          ),
          title: Text('${anno.type.name.toUpperCase()} (Page ${anno.pageNumber})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          subtitle: Text(
            anno.text.isNotEmpty ? anno.text : 'Position: ${anno.rect.topLeft.toString()}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            onPressed: () => ref.read(annotationProvider.notifier).deleteAnnotation(anno.id),
          ),
          onTap: () {
            ref.read(navigationProvider.notifier).setPage(anno.pageNumber);
            ref.read(annotationProvider.notifier).selectAnnotation(anno);
          },
        );
      },
    );
  }

  // --- 5. Search Results Tab ---
  Widget _buildSearchTab(DocumentState docState) {
    final searchState = ref.watch(searchProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search text...',
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchProvider.notifier).clearSearch();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (val) {
              ref.read(searchProvider.notifier).performSearch(val, docState.engine);
            },
          ),
        ),

        // Search Options (Match Case, Whole Word)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              FilterChip(
                label: const Text('Aa', style: TextStyle(fontSize: 11)),
                selected: searchState.caseSensitive,
                onSelected: (_) => ref.read(searchProvider.notifier).toggleCaseSensitive(docState.engine),
              ),
              FilterChip(
                label: const Text('Whole Word', style: TextStyle(fontSize: 11)),
                selected: searchState.wholeWord,
                onSelected: (_) => ref.read(searchProvider.notifier).toggleWholeWord(docState.engine),
              ),
            ],
          ),
        ),

        if (searchState.isSearching)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),

        if (!searchState.isSearching && searchState.query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${searchState.totalMatches} results found',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: () {
                        ref.read(searchProvider.notifier).prevMatch();
                        final match = ref.read(searchProvider).currentMatch;
                        if (match != null) {
                          ref.read(navigationProvider.notifier).setPage(match.pageNumber);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: () {
                        ref.read(searchProvider.notifier).nextMatch();
                        final match = ref.read(searchProvider).currentMatch;
                        if (match != null) {
                          ref.read(navigationProvider.notifier).setPage(match.pageNumber);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

        const Divider(),

        Expanded(
          child: ListView.builder(
            itemCount: searchState.matches.length,
            itemBuilder: (context, index) {
              final m = searchState.matches[index];
              final isCurrent = searchState.currentMatchIndex == index;

              return ListTile(
                dense: true,
                selected: isCurrent,
                selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                title: Text(
                  m.surroundingSnippet,
                  style: const TextStyle(fontSize: 11),
                ),
                subtitle: Text('Page ${m.pageNumber}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                onTap: () {
                  ref.read(searchProvider.notifier).selectMatch(index);
                  ref.read(navigationProvider.notifier).setPage(m.pageNumber);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
