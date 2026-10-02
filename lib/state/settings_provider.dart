import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/app_database.dart';
import '../../data/models/recent_document.dart';

class SettingsState {
  final AppThemeMode themeMode;
  final bool isSidebarOpen;
  final bool isLeftPanelOpen;
  final int sidebarActiveTab; // 0: Thumbnails, 1: Outline, 2: Bookmarks, 3: Annotations, 4: Search
  final bool isAnnotationRibbonOpen;
  final bool isFullscreen;
  final bool isPresentationMode;
  final List<RecentDocument> recentDocuments;

  const SettingsState({
    this.themeMode = AppThemeMode.corporate,
    this.isSidebarOpen = true,
    this.isLeftPanelOpen = true,
    this.sidebarActiveTab = 0,
    this.isAnnotationRibbonOpen = false,
    this.isFullscreen = false,
    this.isPresentationMode = false,
    this.recentDocuments = const [],
  });

  List<RecentDocument> get favoriteDocuments =>
      recentDocuments.where((d) => d.isFavorite).toList();

  SettingsState copyWith({
    AppThemeMode? themeMode,
    bool? isSidebarOpen,
    bool? isLeftPanelOpen,
    int? sidebarActiveTab,
    bool? isAnnotationRibbonOpen,
    bool? isFullscreen,
    bool? isPresentationMode,
    List<RecentDocument>? recentDocuments,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      isSidebarOpen: isSidebarOpen ?? this.isSidebarOpen,
      isLeftPanelOpen: isLeftPanelOpen ?? this.isLeftPanelOpen,
      sidebarActiveTab: sidebarActiveTab ?? this.sidebarActiveTab,
      isAnnotationRibbonOpen: isAnnotationRibbonOpen ?? this.isAnnotationRibbonOpen,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isPresentationMode: isPresentationMode ?? this.isPresentationMode,
      recentDocuments: recentDocuments ?? this.recentDocuments,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadInitialSettings();
    return const SettingsState();
  }

  Future<void> _loadInitialSettings() async {
    final themeStr = await AppDatabase.instance.getPreference('themeMode');
    AppThemeMode mode = AppThemeMode.corporate;
    if (themeStr != null) {
      mode = AppThemeMode.values.firstWhere(
        (m) => m.name == themeStr,
        orElse: () => AppThemeMode.corporate,
      );
    }
    final leftPanelPref = await AppDatabase.instance.getPreference('isLeftPanelOpen');
    final isLeftOpen = leftPanelPref == null || leftPanelPref == 'true';
    final recentDocs = await AppDatabase.instance.getRecentDocuments();
    state = state.copyWith(themeMode: mode, isLeftPanelOpen: isLeftOpen, recentDocuments: recentDocs);
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await AppDatabase.instance.setPreference('themeMode', mode.name);
  }

  void toggleLeftPanel() {
    final next = !state.isLeftPanelOpen;
    state = state.copyWith(isLeftPanelOpen: next);
    AppDatabase.instance.setPreference('isLeftPanelOpen', next.toString());
  }

  void toggleSidebar() {
    state = state.copyWith(isSidebarOpen: !state.isSidebarOpen);
  }

  void setSidebarTab(int tabIndex) {
    state = state.copyWith(sidebarActiveTab: tabIndex, isSidebarOpen: true);
  }

  void toggleAnnotationRibbon() {
    state = state.copyWith(isAnnotationRibbonOpen: !state.isAnnotationRibbonOpen);
  }

  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  void togglePresentationMode() {
    final next = !state.isPresentationMode;
    state = state.copyWith(
      isPresentationMode: next,
      isSidebarOpen: !next,
      isLeftPanelOpen: !next,
      isAnnotationRibbonOpen: false,
    );
  }

  Future<void> refreshRecentDocuments() async {
    final recents = await AppDatabase.instance.getRecentDocuments();
    state = state.copyWith(recentDocuments: recents);
  }

  Future<void> toggleFavorite(String path) async {
    final doc = state.recentDocuments.firstWhere((d) => d.path == path);
    final newFav = !doc.isFavorite;
    await AppDatabase.instance.toggleFavorite(path, newFav);
    await refreshRecentDocuments();
  }

  Future<void> removeRecentDocument(String path) async {
    await AppDatabase.instance.deleteRecentDocument(path);
    await refreshRecentDocuments();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
