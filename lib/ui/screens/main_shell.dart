import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/shortcuts/app_shortcuts.dart';
import '../../../services/file_service.dart';
import '../../../state/document_provider.dart';
import '../../../state/queue_provider.dart';
import '../../../state/settings_provider.dart';
import 'home_dashboard_screen.dart';
import 'processing_queue_screen.dart';
import 'recent_files_screen.dart';
import 'settings_screen.dart';
import 'tools_hub_screen.dart';
import 'viewer_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final docState = ref.watch(documentProvider);
    final queue = ref.watch(queueProvider);
    final settingsState = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB): const ToggleLeftPanelIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ToggleLeftPanelIntent: CallbackAction<ToggleLeftPanelIntent>(
            onInvoke: (_) {
              ref.read(settingsProvider.notifier).toggleLeftPanel();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            bottomNavigationBar: isMobile
                ? NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (val) => setState(() => _currentIndex = val),
                    height: 62,
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: [
                      const NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.grid_view_outlined),
                        selectedIcon: Icon(Icons.grid_view),
                        label: 'Tools',
                      ),
                      NavigationDestination(
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.menu_book_outlined),
                            if (docState.hasDocument)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        selectedIcon: const Icon(Icons.menu_book),
                        label: 'Viewer',
                      ),
                      NavigationDestination(
                        icon: Badge(
                          isLabelVisible: queue.activeCount > 0,
                          label: Text('${queue.activeCount}'),
                          child: const Icon(Icons.queue_outlined),
                        ),
                        selectedIcon: Badge(
                          isLabelVisible: queue.activeCount > 0,
                          label: Text('${queue.activeCount}'),
                          child: const Icon(Icons.queue),
                        ),
                        label: 'Queue',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.history_outlined),
                        selectedIcon: Icon(Icons.history),
                        label: 'Recent',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings),
                        label: 'Settings',
                      ),
                    ],
                  )
                : null,
            body: Column(
              children: [
                // Top Header Bar
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: theme.appBarTheme.backgroundColor,
                    border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
                  ),
                  child: Row(
                    children: [
                      // Left Panel Toggle (on desktop) & App Brand
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isMobile) ...[
                            IconButton(
                              icon: Icon(
                                settingsState.isLeftPanelOpen ? Icons.menu_open : Icons.menu,
                                size: 22,
                                color: theme.colorScheme.onSurface,
                              ),
                              tooltip: settingsState.isLeftPanelOpen
                                  ? 'Hide Left Panel (Ctrl+B)'
                                  : 'Show Left Panel (Ctrl+B)',
                              onPressed: () => ref.read(settingsProvider.notifier).toggleLeftPanel(),
                            ),
                            const SizedBox(width: 4),
                          ],
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => _currentIndex = 0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.asset(
                                      AppConstants.appLogoIcon,
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppConstants.appName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Active Document Title
                      if (docState.hasDocument) ...[
                        const SizedBox(width: 8),
                        Container(
                          height: 20,
                          width: 1,
                          color: theme.dividerColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.description, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  docState.metadata.title.isNotEmpty ? docState.metadata.title : 'Document.pdf',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (!isMobile) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '(${docState.metadata.pageCount} p.)',
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ] else ...[
                        const Spacer(),
                      ],

                      // Notification Toast / Banner in top bar
                      if (queue.lastNotification != null && !isMobile)
                        InkWell(
                          onTap: () => ref.read(queueProvider.notifier).clearNotification(),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: queue.isErrorNotification ? Colors.red.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: queue.isErrorNotification ? Colors.red : Colors.green, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  queue.isErrorNotification ? Icons.error_outline : Icons.check_circle_outline,
                                  color: queue.isErrorNotification ? Colors.red : Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  queue.lastNotification!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: queue.isErrorNotification ? Colors.red.shade900 : Colors.green.shade900,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.close, size: 14),
                              ],
                            ),
                          ),
                        ),

                      // Open File Quick Action
                      IconButton(
                        icon: const Icon(Icons.file_open_outlined, size: 20),
                        tooltip: 'Open PDF Document',
                        onPressed: () async {
                          final path = await FileService.pickPdfFile();
                          if (path != null) {
                            await ref.read(documentProvider.notifier).openFile(path);
                            setState(() => _currentIndex = 2); // Switch to Viewer
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Main Body (Navigation Rail on Desktop + Screens)
                Expanded(
                  child: Row(
                    children: [
                      if (!isMobile && settingsState.isLeftPanelOpen) ...[
                        LayoutBuilder(
                    builder: (context, constraint) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraint.maxHeight),
                          child: IntrinsicHeight(
                            child: NavigationRail(
                              selectedIndex: _currentIndex,
                              onDestinationSelected: (val) => setState(() => _currentIndex = val),
                              labelType: NavigationRailLabelType.all,
                              leading: const SizedBox(height: 8),
                              destinations: [
                                const NavigationRailDestination(
                                  icon: Icon(Icons.home_outlined),
                                  selectedIcon: Icon(Icons.home),
                                  label: Text('Home'),
                                ),
                                const NavigationRailDestination(
                                  icon: Icon(Icons.grid_view_outlined),
                                  selectedIcon: Icon(Icons.grid_view),
                                  label: Text('Tools'),
                                ),
                                NavigationRailDestination(
                                  icon: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(Icons.menu_book_outlined),
                                      if (docState.hasDocument)
                                        Positioned(
                                          top: -2,
                                          right: -2,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  selectedIcon: const Icon(Icons.menu_book),
                                  label: const Text('Viewer'),
                                ),
                                NavigationRailDestination(
                                  icon: Badge(
                                    isLabelVisible: queue.activeCount > 0,
                                    label: Text('${queue.activeCount}'),
                                    child: const Icon(Icons.queue_outlined),
                                  ),
                                  selectedIcon: Badge(
                                    isLabelVisible: queue.activeCount > 0,
                                    label: Text('${queue.activeCount}'),
                                    child: const Icon(Icons.queue),
                                  ),
                                  label: const Text('Queue'),
                                ),
                                const NavigationRailDestination(
                                  icon: Icon(Icons.history_outlined),
                                  selectedIcon: Icon(Icons.history),
                                  label: Text('Recent'),
                                ),
                                const NavigationRailDestination(
                                  icon: Icon(Icons.settings_outlined),
                                  selectedIcon: Icon(Icons.settings),
                                  label: Text('Settings'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                ],

                // Active Tab Screen
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      HomeDashboardScreen(onNavigateTab: _navigateToTab),
                      ToolsHubScreen(onNavigateTab: _navigateToTab),
                      const ViewerScreen(),
                      const ProcessingQueueScreen(),
                      RecentFilesScreen(onNavigateTab: _navigateToTab),
                      const SettingsScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    ),
    ),
  );
}
}
