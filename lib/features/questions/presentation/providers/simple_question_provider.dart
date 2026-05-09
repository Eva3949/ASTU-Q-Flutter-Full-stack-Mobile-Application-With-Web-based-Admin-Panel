import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/question.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/usecases/vote_answer_usecase.dart';

/// Simple Question Provider for testing
/// Extends ChangeNotifier directly without complex dependencies
class SimpleQuestionProvider extends QuestionProviderInterface {
  List<Question> _questions = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedSubject;
  bool _hasMore = false;

  // Getters
  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedSubject => _selectedSubject;
  bool get hasMore => _hasMore;
  bool get isSearching => _searchQuery.isNotEmpty || _selectedSubject != null;
  int get questionCount => _questions.length;

  SimpleQuestionProvider() {
    // Initialize with empty data
    _questions = [];
    _isLoading = false;
    _errorMessage = null;
  }

  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  @override
  Future<void> refreshQuestions() async {
    try {
      _isRefreshing = true;
      _safeNotify();
      await Future.delayed(const Duration(seconds: 1));
      _questions = []; // Empty for now
      _isRefreshing = false;
      _safeNotify();
    } catch (e) {
      _errorMessage = 'Failed to refresh questions';
      _isRefreshing = false;
      _safeNotify();
    }
  }

  @override
  List<String> getAvailableSubjects() {
    return [
      'Mathematics',
      'Physics',
      'Chemistry',
      'Biology',
      'Computer Science',
    ];
  }

  @override
  Future<void> searchQuestions(String query) async {
    // Mock implementation
    _searchQuery = query;
    _safeNotify();
  }

  @override
  Future<void> filterBySubject(String? subject) async {
    // Mock implementation
    _selectedSubject = subject;
    _safeNotify();
  }

  @override
  Future<void> clearSearchAndFilters() async {
    // Mock implementation
    _searchQuery = '';
    _selectedSubject = null;
    _safeNotify();
  }

  @override
  Future<void> loadMoreQuestions() async {
    // Mock implementation
    _isLoadingMore = true;
    _safeNotify();
    await Future.delayed(const Duration(milliseconds: 500));
    _isLoadingMore = false;
    _safeNotify();
  }

  @override
  Future<void> voteQuestion(int questionId, VoteType voteType) async {
    // Mock implementation
  }
}
