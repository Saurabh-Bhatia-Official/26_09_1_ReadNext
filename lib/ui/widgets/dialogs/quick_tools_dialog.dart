import 'package:flutter/material.dart';
import '../tools/small_tool_tile.dart';
import '../tools/tools_catalog.dart';

class QuickToolsDialog extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const QuickToolsDialog({super.key, this.onNavigateTab});

  static Future<void> show(BuildContext context, {void Function(int tabIndex)? onNavigateTab}) {
    return showDialog(
      context: context,
      builder: (context) => QuickToolsDialog(onNavigateTab: onNavigateTab),
    );
  }

  @override
  State<QuickToolsDialog> createState() => _QuickToolsDialogState();
}

class _QuickToolsDialogState extends State<QuickToolsDialog> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ToolItem> _getFilteredTools() {
    return ToolsCatalog.allTools.where((tool) {
      final matchesCategory = _selectedCategory == 'All' || tool.category == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          tool.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tool.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredTools = _getFilteredTools();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.grid_view, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'All PDF Tools',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Search & Filter Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search 20+ PDF tools...',
                        hintStyle: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Category Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ToolsCatalog.categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Text(cat, style: const TextStyle(fontSize: 11)),
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Small Grid Tiles
              Expanded(
                child: filteredTools.isEmpty
                    ? const Center(child: Text('No tools match your search.'))
                    : Scrollbar(
                        thumbVisibility: true,
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 135,
                            mainAxisExtent: 105,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: filteredTools.length,
                          itemBuilder: (context, index) {
                            return SmallToolTile(
                              tool: filteredTools[index],
                              onNavigateTab: widget.onNavigateTab,
                              onBeforeOpen: () => Navigator.of(context).pop(),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
