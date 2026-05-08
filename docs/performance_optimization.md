# Performance Optimization Guide for ASTU-Q Flutter App

This guide provides comprehensive performance optimization strategies for Flutter applications, specifically tailored for the ASTU-Q question-answering platform.

## 1. Widget Performance

### Use Const Constructors
```dart
// BAD - Rebuilds on every build
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Hello'),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// GOOD - Uses const constructors
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Text('Hello'),
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    );
  }
}
```

### Optimize ListView Performance
```dart
// BAD - Inefficient ListView
class QuestionList extends StatelessWidget {
  final List<Question> questions;

  const QuestionList({Key? key, required this.questions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: questions.length,
      itemBuilder: (context, index) {
        return QuestionCard(question: questions[index]); // Rebuilds entire card
      },
    );
  }
}

// GOOD - Optimized ListView with caching
class OptimizedQuestionList extends StatelessWidget {
  final List<Question> questions;

  const OptimizedQuestionList({Key? key, required this.questions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: questions.length,
      itemBuilder: (context, index) {
        return QuestionCard(
          key: ValueKey(questions[index].id), // Unique key for proper caching
          question: questions[index],
        );
      },
    );
  }
}
```

### Use AutomaticKeepAlive for Complex Items
```dart
class QuestionCard extends StatefulWidget {
  final Question question;

  const QuestionCard({Key? key, required this.question}) : super(key: key);

  @override
  _QuestionCardState createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // Keep widget alive when scrolled away

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.question.title),
            Text(widget.question.content),
            // ... other widgets
          ],
        ),
      ),
    );
  }
}
```

## 2. State Management Optimization

### Use Selector Instead of Consumer for Specific Values
```dart
// BAD - Consumer rebuilds entire widget when any state changes
Consumer<QuestionProvider>(
  builder: (context, provider, child) {
    return Column(
      children: [
        Text('Total Questions: ${provider.questions.length}'),
        Text('Loading: ${provider.isLoading}'),
        // Other widgets that don't need to rebuild
        SomeComplexWidget(),
      ],
    );
  },
)

// GOOD - Selector only rebuilds when specific value changes
Selector<QuestionProvider, int>(
  selector: (context, provider) => provider.questions.length,
  builder: (context, questionCount, child) {
    return Text('Total Questions: $questionCount');
  },
)

// Separate selectors for different values
Column(
  children: [
    Selector<QuestionProvider, int>(
      selector: (context, provider) => provider.questions.length,
      builder: (context, count, child) => Text('Total: $count'),
    ),
    Selector<QuestionProvider, bool>(
      selector: (context, provider) => provider.isLoading,
      builder: (context, loading, child) => Text('Loading: $loading'),
    ),
    SomeComplexWidget(), // Doesn't rebuild unnecessarily
  ],
)
```

### Optimize Provider Updates
```dart
class QuestionProvider extends ChangeNotifier {
  List<Question> _questions = [];
  bool _isLoading = false;
  
  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;

  // BAD - notifyListeners() called unnecessarily
  void setLoadingBad(bool loading) {
    _isLoading = loading;
    notifyListeners(); // Notifies all listeners even if value didn't change
  }

  // GOOD - Only notify if value actually changes
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // GOOD - Batch updates
  void updateQuestionsAndLoading(List<Question> newQuestions, bool loading) {
    bool questionsChanged = _questions != newQuestions;
    bool loadingChanged = _isLoading != loading;
    
    _questions = newQuestions;
    _isLoading = loading;
    
    if (questionsChanged || loadingChanged) {
      notifyListeners();
    }
  }
}
```

## 3. Image Optimization

### Use Cached Network Images
```dart
// BAD - Re-downloads images every time
Image.network(question.authorAvatarUrl)

// GOOD - Use cached network image with placeholders
CachedNetworkImage(
  imageUrl: question.authorAvatarUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  memCacheWidth: 100, // Limit cache size
  memCacheHeight: 100,
)

// EVEN BETTER - Custom image widget with optimization
class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;

  const OptimizedNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.error),
      ),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      fit: BoxFit.cover,
    );
  }
}
```

### Optimize Image Loading for Lists
```dart
class QuestionListItem extends StatelessWidget {
  final Question question;

  const QuestionListItem({Key? key, required this.question}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: OptimizedNetworkImage(
        imageUrl: question.authorAvatarUrl,
        width: 40,
        height: 40,
      ),
      title: Text(question.title),
      subtitle: Text(question.authorName),
    );
  }
}
```

## 4. Network Optimization

### Implement Request Caching
```dart
class CachedApiService {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  static Future<T> getCachedData<T>(
    String key,
    Future<T> Function() fetcher,
  ) async {
    // Check cache
    if (_cache.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null && 
          DateTime.now().difference(timestamp) < _cacheDuration) {
        return _cache[key] as T;
      }
    }

    // Fetch new data
    final data = await fetcher();
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    return data;
  }

  static Future<List<Question>> getQuestions() async {
    return getCachedData(
      'questions',
      () => _fetchQuestionsFromApi(),
    );
  }

  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}
```

### Implement Request Debouncing
```dart
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }
}

// Usage in search
class SearchWidget extends StatefulWidget {
  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final _debouncer = Debouncer(delay: Duration(milliseconds: 500));
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchController,
      onChanged: (query) {
        _debouncer.run(() {
          _performSearch(query);
        });
      },
    );
  }

  void _performSearch(String query) {
    // Perform search API call
  }
}
```

### Optimize HTTP Requests
```dart
class OptimizedApiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.astuq.app',
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
    sendTimeout: Duration(seconds: 10),
  ));

  static Future<List<Question>> getQuestions({
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    try {
      final response = await _dio.get('/questions', queryParameters: {
        'page': page,
        'limit': limit,
        if (category != null) 'category': category,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return List<Question>.from(
            data['data']['items'].map((item) => Question.fromJson(item)),
          );
        }
      }
      throw Exception('Failed to load questions');
    } on DioError catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // Batch multiple requests
  static Future<Map<String, dynamic>> getBatchData() async {
    final responses = await Future.wait([
      _dio.get('/questions'),
      _dio.get('/categories'),
      _dio.get('/users/top'),
    ]);

    return {
      'questions': responses[0].data,
      'categories': responses[1].data,
      'topUsers': responses[2].data,
    };
  }
}
```

## 5. Memory Management

### Dispose Resources Properly
```dart
class QuestionDetailScreen extends StatefulWidget {
  final int questionId;

  const QuestionDetailScreen({Key? key, required this.questionId}) : super(key: key);

  @override
  _QuestionDetailScreenState createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  StreamSubscription? _questionSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    // Subscribe to question updates
    _questionSubscription = QuestionService()
        .getQuestionStream(widget.questionId)
        .listen((question) {
      setState(() {
        // Update UI
      });
    });

    // Start refresh timer
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _refreshQuestion();
    });
  }

  @override
  void dispose() {
    // Dispose all resources
    _animationController.dispose();
    _questionSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _refreshQuestion() {
    // Refresh question data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _animationController,
            child: child,
          );
        },
        child: QuestionContent(questionId: widget.questionId),
      ),
    );
  }
}
```

### Use Memory-Efficient Data Structures
```dart
// BAD - Storing all questions in memory
class QuestionProvider extends ChangeNotifier {
  List<Question> _allQuestions = []; // Could be thousands of items
  
  Future<void> loadAllQuestions() async {
    _allQuestions = await ApiService.getAllQuestions(); // Memory intensive
    notifyListeners();
  }
}

// GOOD - Pagination and lazy loading
class OptimizedQuestionProvider extends ChangeNotifier {
  final Map<int, Question> _questionCache = {};
  final List<int> _questionIds = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 20;

  List<Question> get questions {
    return _questionIds
        .map((id) => _questionCache[id])
        .where((question) => question != null)
        .cast<Question>()
        .toList();
  }

  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> loadMoreQuestions() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newQuestions = await ApiService.getQuestions(
        page: _currentPage,
        limit: _pageSize,
      );

      for (final question in newQuestions) {
        _questionCache[question.id] = question;
        if (!_questionIds.contains(question.id)) {
          _questionIds.add(question.id);
        }
      }

      _currentPage++;
      _hasMore = newQuestions.length == _pageSize;
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshQuestions() async {
    _questionCache.clear();
    _questionIds.clear();
    _currentPage = 1;
    _hasMore = true;
    await loadMoreQuestions();
  }
}
```

## 6. Build Performance

### Optimize Build Methods
```dart
// BAD - Complex logic in build method
class BadWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Complex calculations in build method
    final expensiveCalculation = _calculateSomethingExpensive();
    final filteredList = _filterLargeList();
    final formattedText = _formatComplexText();
    
    return Column(
      children: [
        Text(expensiveCalculation.toString()),
        ListView.builder(
          itemCount: filteredList.length,
          itemBuilder: (context, index) => Text(filteredList[index]),
        ),
        Text(formattedText),
      ],
    );
  }
}

// GOOD - Extract calculations and use const
class GoodWidget extends StatelessWidget {
  // Calculate once or memoize
  final int _expensiveCalculation = _calculateSomethingExpensive();
  final List<String> _filteredList = _filterLargeList();
  final String _formattedText = _formatComplexText();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ExpensiveCalculationWidget(),
        _FilteredListWidget(),
        _FormattedTextWidget(),
      ],
    );
  }
}
```

### Use Memoization
```dart
class MemoizedWidget extends StatefulWidget {
  final String input;

  const MemoizedWidget({Key? key, required this.input}) : super(key: key);

  @override
  _MemoizedWidgetState createState() => _MemoizedWidgetState();
}

class _MemoizedWidgetState extends State<MemoizedWidget> {
  String? _cachedResult;
  String? _lastInput;

  String _processInput(String input) {
    if (_lastInput == input && _cachedResult != null) {
      return _cachedResult!;
    }

    final result = _expensiveProcessing(input);
    _cachedResult = result;
    _lastInput = input;
    return result;
  }

  String _expensiveProcessing(String input) {
    // Simulate expensive computation
    return input.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final processedText = _processInput(widget.input);
    return Text(processedText);
  }
}
```

## 7. Async Operations Optimization

### Use Isolates for Heavy Computations
```dart
import 'dart:isolate';

class IsolateService {
  static Future<List<Question>> filterQuestionsIsolate(
    List<Question> questions,
    String filter,
  ) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_filterQuestionsWorker, [
      receivePort.sendPort,
      questions,
      filter,
    ]);

    final result = await receivePort.first as List<Question>;
    return result;
  }

  static void _filterQuestionsWorker(List<dynamic> args) async {
    final sendPort = args[0] as SendPort;
    final questions = args[1] as List<Question>;
    final filter = args[2] as String;

    // Heavy filtering logic
    final filtered = questions
        .where((q) => q.title.toLowerCase().contains(filter.toLowerCase()))
        .toList();

    sendPort.send(filtered);
  }
}

// Usage
class QuestionFilterWidget extends StatefulWidget {
  @override
  _QuestionFilterWidgetState createState() => _QuestionFilterWidgetState();
}

class _QuestionFilterWidgetState extends State<QuestionFilterWidget> {
  List<Question> _filteredQuestions = [];
  bool _isFiltering = false;

  Future<void> _filterQuestions(String filter) async {
    setState(() {
      _isFiltering = true;
    });

    try {
      final filtered = await IsolateService.filterQuestionsIsolate(
        widget.questions,
        filter,
      );
      setState(() {
        _filteredQuestions = filtered;
        _isFiltering = false;
      });
    } catch (e) {
      setState(() {
        _isFiltering = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: _filterQuestions,
        ),
        if (_isFiltering)
          CircularProgressIndicator()
        else
          Expanded(
            child: ListView.builder(
              itemCount: _filteredQuestions.length,
              itemBuilder: (context, index) {
                return QuestionCard(question: _filteredQuestions[index]);
              },
            ),
          ),
      ],
    );
  }
}
```

### Optimize Future Usage
```dart
// BAD - Sequential async operations
Future<void> loadSequentialData() async {
  await loadQuestions();
  await loadCategories();
  await loadUsers();
}

// GOOD - Parallel async operations
Future<void> loadParallelData() async {
  await Future.wait([
    loadQuestions(),
    loadCategories(),
    loadUsers(),
  ]);
}

// EVEN BETTER - Selective parallel loading
Future<AppData> loadAppData() async {
  final results = await Future.wait([
    loadQuestions(),
    loadCategories(),
    loadUsers(),
  ]);

  return AppData(
    questions: results[0],
    categories: results[1],
    users: results[2],
  );
}
```

## 8. Rendering Optimization

### Use RepaintBoundary
```dart
class OptimizedList extends StatelessWidget {
  final List<Item> items;

  const OptimizedList({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: ItemWidget(item: items[index]),
        );
      },
    );
  }
}
```

### Optimize Custom Paint
```dart
class OptimizedCustomPaint extends CustomPainter {
  final List<Point> points;

  OptimizedCustomPaint(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(OptimizedCustomPaint oldDelegate) {
    // Only repaint if points actually changed
    return oldDelegate.points != points;
  }
}
```

## 9. Performance Monitoring

### Performance Overlay
```dart
class PerformanceMonitor extends StatefulWidget {
  final Widget child;

  const PerformanceMonitor({Key? key, required this.child}) : super(key: key);

  @override
  _PerformanceMonitorState createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  final Stopwatch _stopwatch = Stopwatch();
  int _frameCount = 0;
  Duration _totalFrameTime = Duration.zero;

  @override
  Widget build(BuildContext context) {
    _stopwatch.start();
    
    return Stack(
      children: [
        widget.child,
        if (kDebugMode)
          Positioned(
            top: 50,
            right: 10,
            child: Container(
              padding: EdgeInsets.all(8),
              color: Colors.black54,
              child: Text(
                'FPS: ${_calculateFps().toStringAsFixed(1)}',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  double _calculateFps() {
    _frameCount++;
    _totalFrameTime += _stopwatch.elapsed;
    
    if (_totalFrameTime.inSeconds >= 1) {
      final fps = _frameCount / _totalFrameTime.inSeconds.toDouble();
      _frameCount = 0;
      _totalFrameTime = Duration.zero;
      _stopwatch.reset();
      return fps;
    }
    
    return _frameCount / _totalFrameTime.inSeconds.toDouble();
  }
}
```

### Memory Usage Monitor
```dart
class MemoryMonitor {
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      // Note: This would require dart:developer import
      // and platform-specific memory monitoring
      print('Memory usage at $context: [Memory info]');
    }
  }

  static void checkMemoryLeaks() {
    if (kDebugMode) {
      // Add memory leak detection logic
      print('Checking for memory leaks...');
    }
  }
}
```

## 10. Build Configuration Optimization

### Optimize pubspec.yaml
```yaml
# pubspec.yaml
name: astuq
description: Academic Questions & Answers Platform

environment:
  sdk: '>=2.17.0 <3.0.0'
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter
  
  # Core dependencies
  cupertino_icons: ^1.0.2
  
  # Network and storage
  dio: ^5.0.0
  shared_preferences: ^2.0.0
  
  # State management
  provider: ^6.0.0
  
  # UI components
  flutter_screenutil: ^5.0.0
  cached_network_image: ^3.0.0
  
  # Utilities
  image_picker: ^1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
  
  # Performance tools
  flutter_driver:
    sdk: flutter
  integration_test:
    sdk: flutter

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
  
  fonts:
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
        - asset: fonts/Roboto-Bold.ttf

# Performance optimizations
flutter:
  # Enable tree shaking
  tree-shake-icons: true
  
  # Optimize assets
  assets:
    - assets/images/
    - assets/icons/
  
  # Exclude unused fonts in production
  fonts:
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
        - asset: fonts/Roboto-Bold.ttf
```

### Build Commands
```bash
# Development builds with debugging
flutter run --debug
flutter run --profile

# Production builds
flutter build apk --release
flutter build ios --release

# Build with specific optimizations
flutter build apk --release --shrink --split-per-abi
flutter build web --release --web-renderer canvaskit

# Analyze performance
flutter run --profile --trace-startup
flutter drive --target=test_driver/app.dart
```

## 11. Best Practices Summary

### DO
- Use const constructors for immutable widgets
- Implement proper disposal of resources
- Use RepaintBoundary for complex widgets
- Cache network images and data
- Implement pagination for large lists
- Use Selector instead of Consumer when possible
- Optimize build methods and avoid heavy computations
- Use AutomaticKeepAlive for complex list items
- Implement proper error handling
- Monitor performance in debug builds

### DON'T
- Create widgets unnecessarily in build methods
- Forget to dispose controllers, subscriptions, and timers
- Use expensive operations in build methods
- Load all data at once for large datasets
- Ignore memory leaks
- Use nested ListView without constraints
- Forget to add unique keys to list items
- Ignore performance warnings in Flutter DevTools
- Use setState() for state that can be handled by Provider
- Ignore build warnings and analyzer suggestions

This comprehensive performance optimization guide will help ensure the ASTU-Q app runs smoothly and efficiently across all devices and platforms.
