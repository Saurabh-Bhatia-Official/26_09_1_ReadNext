import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../services/pdf/i_pdf_engine.dart';

class SearchState {
  final bool isOpen;
  final String query;
  final bool caseSensitive;
  final bool wholeWord;
  final List<SearchMatch> matches;
  final int currentMatchIndex; // 0-indexed
  final bool isSearching;
  final List<String> history;

  const SearchState({
    this.isOpen = false,
    this.query = '',
    this.caseSensitive = false,
    this.wholeWord = false,
    this.matches = const [],
    this.currentMatchIndex = 0,
    this.isSearching = false,
    this.history = const [],
  });

  int get totalMatches => matches.length;
  SearchMatch? get currentMatch =>
      matches.isNotEmpty && currentMatchIndex < matches.length
          ? matches[currentMatchIndex]
          : null;

  SearchState copyWith({
    bool? isOpen,
    String? query,
    bool? caseSensitive,
    bool? wholeWord,
    List<SearchMatch>? matches,
    int? currentMatchIndex,
    bool? isSearching,
    List<String>? history,
  }) {
    return SearchState(
      isOpen: isOpen ?? this.isOpen,
      query: query ?? this.query,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      wholeWord: wholeWord ?? this.wholeWord,
      matches: matches ?? this.matches,
      currentMatchIndex: currentMatchIndex ?? this.currentMatchIndex,
      isSearching: isSearching ?? this.isSearching,
      history: history ?? this.history,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() {
    _loadHistory();
    return const SearchState();
  }

  Future<void> _loadHistory() async {
    final history = await AppDatabase.instance.getSearchHistory();
    state = state.copyWith(history: history);
  }

  void toggleSearch() {
    state = state.copyWith(isOpen: !state.isOpen);
  }

  void closeSearch() {
    state = state.copyWith(isOpen: false);
  }

  Future<void> performSearch(String query, IPdfEngine engine) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      state = state.copyWith(query: '', matches: [], currentMatchIndex: 0);
      return;
    }

    state = state.copyWith(query: cleanQuery, isSearching: true);
    await AppDatabase.instance.addSearchQuery(cleanQuery);
    await _loadHistory();

    final results = await engine.search(
      cleanQuery,
      caseSensitive: state.caseSensitive,
      wholeWord: state.wholeWord,
    );

    state = state.copyWith(
      matches: results,
      currentMatchIndex: 0,
      isSearching: false,
    );
  }

  Future<void> toggleCaseSensitive(IPdfEngine engine) async {
    final newCase = !state.caseSensitive;
    state = state.copyWith(caseSensitive: newCase);
    if (state.query.isNotEmpty) {
      await performSearch(state.query, engine);
    }
  }

  Future<void> toggleWholeWord(IPdfEngine engine) async {
    final newWhole = !state.wholeWord;
    state = state.copyWith(wholeWord: newWhole);
    if (state.query.isNotEmpty) {
      await performSearch(state.query, engine);
    }
  }

  void nextMatch() {
    if (state.matches.isEmpty) return;
    final next = (state.currentMatchIndex + 1) % state.matches.length;
    state = state.copyWith(currentMatchIndex: next);
  }

  void prevMatch() {
    if (state.matches.isEmpty) return;
    final prev = (state.currentMatchIndex - 1 + state.matches.length) % state.matches.length;
    state = state.copyWith(currentMatchIndex: prev);
  }

  void selectMatch(int index) {
    if (index >= 0 && index < state.matches.length) {
      state = state.copyWith(currentMatchIndex: index);
    }
  }

  void clearSearch() {
    state = state.copyWith(
      query: '',
      matches: [],
      currentMatchIndex: 0,
    );
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
