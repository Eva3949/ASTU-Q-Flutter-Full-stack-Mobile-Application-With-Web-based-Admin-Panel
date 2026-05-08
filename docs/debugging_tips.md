# Debugging Tips for ASTU-Q Flutter App

This guide provides comprehensive debugging strategies and techniques for Flutter development, specifically tailored for the ASTU-Q application.

## 1. Flutter Debugging Tools

### Flutter Inspector
```bash
# Enable Flutter Inspector
flutter run --debug

# Open Flutter Inspector in browser
# Go to: http://localhost:12345/#/inspector
```

### Flutter DevTools
```bash
# Start DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Or open from VS Code
# Command Palette > Flutter: Open Flutter DevTools
```

### Debug Console Commands
```dart
// Print statements for debugging
print('Debug: Variable value = $variable');
debugPrint('Debug: This is a debug message');

// Assert for development-only checks
assert(condition, 'Error message if condition is false');

// Debug banner
MaterialApp(
  debugShowCheckedModeBanner: true, // Keep enabled during development
)
```

## 2. Logging and Debug Output

### Custom Logger Implementation
```dart
class AppLogger {
  static const String _tag = 'ASTU-Q';
  
  static void d(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('[$_tag] DEBUG: $message');
      if (error != null) {
        debugPrint('[$_tag] ERROR: $error');
      }
      if (stackTrace != null) {
        debugPrint('[$_tag] STACK: $stackTrace');
      }
    }
  }
  
  static void i(String message, {Object? error}) {
    debugPrint('[$_tag] INFO: $message');
    if (error != null) {
      debugPrint('[$_tag] ERROR: $error');
    }
  }
  
  static void w(String message, {Object? error}) {
    debugPrint('[$_tag] WARNING: $message');
    if (error != null) {
      debugPrint('[$_tag] ERROR: $error');
    }
  }
  
  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('[$_tag] ERROR: $message');
    if (error != null) {
      debugPrint('[$_tag] ERROR: $error');
    }
    if (stackTrace != null) {
      debugPrint('[$_tag] STACK: $stackTrace');
    }
  }
}
```

### Network Request Debugging
```dart
class NetworkLogger {
  static void logRequest(String method, String url, Map<String, dynamic>? data) {
    AppLogger.d('Network Request: $method $url');
    if (data != null) {
      AppLogger.d('Request Body: ${jsonEncode(data)}');
    }
  }
  
  static void logResponse(String url, int statusCode, dynamic response) {
    AppLogger.d('Network Response: $url - Status: $statusCode');
    if (response != null) {
      AppLogger.d('Response Body: ${jsonEncode(response)}');
    }
  }
  
  static void logError(String url, dynamic error) {
    AppLogger.e('Network Error: $url - Error: $error');
  }
}
```

## 3. State Management Debugging

### Provider Debugging
```dart
// Enable Provider debugging
void main() {
  Provider.debugCheckInvalidValueType = true;
  runApp(MyApp());
}

// Debug Provider state changes
class DebugProvider extends ChangeNotifier {
  int _counter = 0;
  
  int get counter => _counter;
  
  void increment() {
    AppLogger.d('Counter before increment: $_counter');
    _counter++;
    AppLogger.d('Counter after increment: $_counter');
    notifyListeners();
  }
  
  @override
  void notifyListeners() {
    AppLogger.d('notifyListeners called');
    super.notifyListeners();
  }
}

// Provider debugging widget
class ProviderDebugger extends StatelessWidget {
  final Widget child;
  
  const ProviderDebugger({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<DebugProvider>(
      builder: (context, provider, child) {
        AppLogger.d('Provider rebuild - Counter: ${provider.counter}');
        return child!;
      },
      child: child,
    );
  }
}
```

### State Change Tracking
```dart
class StateTracker {
  static final Map<String, dynamic> _stateHistory = {};
  
  static void trackState(String widgetName, dynamic state) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _stateHistory['${widgetName}_$timestamp'] = state;
    
    // Keep only last 100 state changes
    if (_stateHistory.length > 100) {
      final keys = _stateHistory.keys.toList()..sort();
      for (int i = 0; i < 10; i++) {
        _stateHistory.remove(keys[i]);
      }
    }
    
    AppLogger.d('State tracked for $widgetName: $state');
  }
  
  static void printHistory(String widgetName) {
    AppLogger.d('State history for $widgetName:');
    _stateHistory.forEach((key, value) {
      if (key.startsWith(widgetName)) {
        AppLogger.d('  $key: $value');
      }
    });
  }
}
```

## 4. Widget Debugging

### Widget Tree Inspection
```dart
class WidgetInspector extends StatefulWidget {
  final Widget child;
  
  const WidgetInspector({Key? key, required this.child}) : super(key: key);
  
  @override
  _WidgetInspectorState createState() => _WidgetInspectorState();
}

class _WidgetInspectorState extends State<WidgetInspector> {
  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: widget.child,
      );
    }
    return widget.child;
  }
}

// Usage
WidgetInspector(
  child: MyComplexWidget(),
)
```

### Build Method Debugging
```dart
class DebugWidget extends StatefulWidget {
  @override
  _DebugWidgetState createState() => _DebugWidgetState();
}

class _DebugWidgetState extends State<DebugWidget> {
  int _buildCount = 0;
  
  @override
  Widget build(BuildContext context) {
    _buildCount++;
    AppLogger.d('DebugWidget build count: $_buildCount');
    
    return Container(
      child: Text('Build count: $_buildCount'),
    );
  }
}
```

### Layout Debugging
```dart
class LayoutDebugger extends StatelessWidget {
  final Widget child;
  final String? name;
  
  const LayoutDebugger({Key? key, required this.child, this.name}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      return LayoutBuilder(
        builder: (context, constraints) {
          AppLogger.d('Layout Debug - ${name ?? "Widget"}: '
              'Size: ${constraints.maxWidth}x${constraints.maxHeight}');
          
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.withOpacity(0.5)),
            ),
            child: Stack(
              children: [
                child,
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    color: Colors.blue.withOpacity(0.8),
                    child: Text(
                      '${constraints.maxWidth.toInt()}x${constraints.maxHeight.toInt()}',
                      style: TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
    return child;
  }
}
```

## 5. Performance Debugging

### Performance Monitoring
```dart
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  
  static void startTimer(String name) {
    _timers[name] = Stopwatch()..start();
    AppLogger.d('Timer started: $name');
  }
  
  static void endTimer(String name) {
    final timer = _timers[name];
    if (timer != null) {
      timer.stop();
      AppLogger.d('Timer ended: $name - Duration: ${timer.elapsedMilliseconds}ms');
      _timers.remove(name);
    }
  }
  
  static void measureFunction(String name, Function() function) {
    startTimer(name);
    function();
    endTimer(name);
  }
}

// Usage
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    PerformanceMonitor.measureFunction('MyWidget.build', () {
      return Container(
        child: Text('Hello World'),
      );
    });
  }
}
```

### Memory Debugging
```dart
class MemoryMonitor {
  static void logMemoryUsage(String context) {
    // Note: This requires dart:developer import
    if (kDebugMode) {
      // Simplified memory logging
      AppLogger.d('Memory usage at $context: [Memory info would go here]');
    }
  }
  
  static void checkMemoryLeaks() {
    if (kDebugMode) {
      AppLogger.d('Checking for memory leaks...');
      // Add memory leak detection logic
    }
  }
}
```

## 6. Network Debugging

### HTTP Request Debugging
```dart
class DebugHttpClient extends BaseClient {
  final Client _inner;
  
  DebugHttpClient(this._inner);
  
  @override
  Future<Response> head(Uri url, {Map<String, String>? headers}) {
    AppLogger.d('HTTP HEAD: $url');
    return _inner.head(url, headers: headers);
  }
  
  @override
  Future<Response> get(Uri url, {Map<String, String>? headers}) {
    AppLogger.d('HTTP GET: $url');
    AppLogger.d('Headers: $headers');
    return _inner.get(url, headers: headers).then((response) {
      AppLogger.d('Response Status: ${response.statusCode}');
      AppLogger.d('Response Body: ${response.body}');
      return response;
    });
  }
  
  @override
  Future<Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    AppLogger.d('HTTP POST: $url');
    AppLogger.d('Headers: $headers');
    AppLogger.d('Body: $body');
    return _inner.post(url, headers: headers, body: body, encoding: encoding).then((response) {
      AppLogger.d('Response Status: ${response.statusCode}');
      AppLogger.d('Response Body: ${response.body}');
      return response;
    });
  }
}
```

### API Response Debugging
```dart
class ApiDebugger {
  static void debugResponse(String endpoint, Map<String, dynamic> response) {
    AppLogger.d('=== API Response Debug ===');
    AppLogger.d('Endpoint: $endpoint');
    AppLogger.d('Response Keys: ${response.keys.toList()}');
    
    if (response.containsKey('data')) {
      final data = response['data'];
      if (data is Map) {
        AppLogger.d('Data Keys: ${data.keys.toList()}');
      }
    }
    
    if (response.containsKey('error')) {
      AppLogger.d('Error: ${response['error']}');
    }
    
    AppLogger.d('========================');
  }
}
```

## 7. Error Handling Debugging

### Error Boundary
```dart
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Function(Object error, StackTrace stackTrace)? onError;
  
  const ErrorBoundary({Key? key, required this.child, this.onError}) : super(key: key);
  
  @override
  _ErrorBoundaryState createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;
  
  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      setState(() {
        _error = details.exception;
        _stackTrace = details.stack;
      });
      widget.onError?.call(details.exception, details.stack!);
    };
  }
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorWidget(_error!);
    }
    return widget.child;
  }
}
```

### Exception Logging
```dart
class ExceptionLogger {
  static void logException(Object exception, StackTrace stackTrace, {String? context}) {
    AppLogger.e('Exception caught: $exception', error: exception, stackTrace: stackTrace);
    
    if (context != null) {
      AppLogger.e('Context: $context');
    }
    
    // Log to external service in production
    if (!kDebugMode) {
      // Send to crash reporting service
    }
  }
  
  static void logFlutterError(FlutterErrorDetails details) {
    AppLogger.e('Flutter Error: ${details.exception}', 
               error: details.exception, 
               stackTrace: details.stack);
    
    AppLogger.e('Widget: ${details.widget}');
    AppLogger.e('Library: ${details.library}');
    AppLogger.e('Context: ${details.context}');
  }
}
```

## 8. Specific ASTU-Q Debugging

### Authentication Debugging
```dart
class AuthDebugger {
  static void logAuthState(String state, {Map<String, dynamic>? data}) {
    AppLogger.d('=== Auth State Debug ===');
    AppLogger.d('State: $state');
    if (data != null) {
      AppLogger.d('Data: $data');
    }
    AppLogger.d('=====================');
  }
  
  static void logTokenValidation(String token, bool isValid) {
    AppLogger.d('Token Validation: $isValid');
    if (!isValid) {
      AppLogger.d('Invalid Token: $token');
    }
  }
  
  static void logLoginAttempt(String email, bool success) {
    AppLogger.d('Login Attempt: $email - Success: $success');
  }
}
```

### Question/Answer Debugging
```dart
class QADebugger {
  static void logQuestionAction(String action, int questionId, {Map<String, dynamic>? data}) {
    AppLogger.d('Question Action: $action - ID: $questionId');
    if (data != null) {
      AppLogger.d('Action Data: $data');
    }
  }
  
  static void logVoteAction(String type, int targetId, bool isUpvote) {
    AppLogger.d('Vote Action: $type - ID: $targetId - Upvote: $isUpvote');
  }
  
  static void logSearchQuery(String query, int resultCount) {
    AppLogger.d('Search Query: "$query" - Results: $resultCount');
  }
}
```

### Chat Debugging
```dart
class ChatDebugger {
  static void logMessage(String roomId, String message, String sender) {
    AppLogger.d('Chat Message - Room: $roomId, Sender: $sender, Message: "$message"');
  }
  
  static void logConnectionState(String state) {
    AppLogger.d('Chat Connection State: $state');
  }
  
  static void logRealtimeEvent(String event, dynamic data) {
    AppLogger.d('Realtime Event: $event - Data: $data');
  }
}
```

## 9. Testing Debugging

### Unit Test Debugging
```dart
void main() {
  group('Auth Tests', () {
    test('Login should succeed with valid credentials', () async {
      // Arrange
      final authProvider = AuthProvider();
      final email = 'test@example.com';
      final password = 'password123';
      
      // Act
      AppLogger.d('Starting login test with email: $email');
      final result = await authProvider.login(email, password);
      
      // Assert
      expect(result.success, true);
      AppLogger.d('Login test passed');
    });
  });
}
```

### Widget Test Debugging
```dart
void main() {
  testWidgets('Question card should display correctly', (WidgetTester tester) async {
    // Arrange
    final question = Question(
      id: 1,
      title: 'Test Question',
      content: 'Test content',
      author: 'Test Author',
    );
    
    AppLogger.d('Building question card widget');
    await tester.pumpWidget(
      MaterialApp(
        home: QuestionCardWidget(question: question),
      ),
    );
    
    // Act
    AppLogger.d('Looking for title text');
    final titleFinder = find.text('Test Question');
    expect(titleFinder, findsOneWidget);
    
    AppLogger.d('Question card test passed');
  });
}
```

## 10. Common Debugging Scenarios

### Widget Not Updating
```dart
// Problem: Widget not rebuilding when state changes
// Solution: Check notifyListeners() and Consumer usage

class DebugProvider extends ChangeNotifier {
  int _value = 0;
  int get value => _value;
  
  void increment() {
    AppLogger.d('Before increment: $_value');
    _value++;
    AppLogger.d('After increment: $_value');
    AppLogger.d('Calling notifyListeners');
    notifyListeners();
    AppLogger.d('notifyListeners called');
  }
}

// In widget:
Consumer<DebugProvider>(
  builder: (context, provider, child) {
    AppLogger.d('Consumer rebuilding with value: ${provider.value}');
    return Text('Value: ${provider.value}');
  },
)
```

### Navigation Issues
```dart
// Problem: Navigation not working
// Solution: Check route definitions and context

class NavigationDebugger {
  static void debugNavigation(String route, BuildContext context) {
    AppLogger.d('Attempting navigation to: $route');
    AppLogger.d('Current route: ${ModalRoute.of(context)?.settings.name}');
    AppLogger.d('Navigator can pop: ${Navigator.canPop(context)}');
  }
  
  static void safeNavigate(BuildContext context, String route) {
    debugNavigation(route, context);
    try {
      Navigator.pushNamed(context, route);
      AppLogger.d('Navigation successful');
    } catch (e) {
      AppLogger.e('Navigation failed: $e');
    }
  }
}
```

### Async Operation Issues
```dart
// Problem: Async operations not completing
// Solution: Add proper error handling and logging

class AsyncDebugger {
  static Future<T> debugAsyncOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    AppLogger.d('Starting async operation: $operationName');
    try {
      final result = await operation();
      AppLogger.d('Async operation completed: $operationName');
      return result;
    } catch (e, stackTrace) {
      AppLogger.e('Async operation failed: $operationName', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

// Usage
final result = await AsyncDebugger.debugAsyncOperation(
  'fetchQuestions',
  () => apiService.getQuestions(),
);
```

## 11. Debugging Best Practices

### 1. Use Debug Flags
```dart
const bool DEBUG_AUTH = true;
const bool DEBUG_NETWORK = true;
const bool DEBUG_PERFORMANCE = false;

if (DEBUG_AUTH) {
  AppLogger.d('Auth debug info');
}
```

### 2. Structured Logging
```dart
class StructuredLogger {
  static void log(String level, String category, String message, {Map<String, dynamic>? data}) {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level,
      'category': category,
      'message': message,
      'data': data,
    };
    
    if (kDebugMode) {
      print(jsonEncode(logEntry));
    }
  }
}
```

### 3. Conditional Debugging
```dart
class ConditionalDebugger {
  static bool shouldDebug(String category) {
    // Check environment variables, build flags, etc.
    return kDebugMode;
  }
  
  static void debug(String category, String message) {
    if (shouldDebug(category)) {
      AppLogger.d('[$category] $message');
    }
  }
}
```

### 4. Performance Profiling
```dart
class Profiler {
  static void profile(String name, VoidCallback callback) {
    final stopwatch = Stopwatch()..start();
    callback();
    stopwatch.stop();
    AppLogger.d('Profile [$name]: ${stopwatch.elapsedMilliseconds}ms');
  }
}
```

## 12. Remote Debugging

### Firebase Crashlytics Integration
```dart
class CrashlyticsLogger {
  static void logError(String message, dynamic error, StackTrace? stackTrace) {
    if (!kDebugMode) {
      // Send to Firebase Crashlytics
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: false,
        information: [DiagnosticsProperty('message', message)],
      );
    }
  }
  
  static void setUserIdentifier(String userId) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }
  }
}
```

### Remote Configuration Debugging
```dart
class RemoteConfigDebugger {
  static void debugRemoteConfig() {
    if (kDebugMode) {
      FirebaseRemoteConfig.instance.getAll().forEach((key, value) {
        AppLogger.d('Remote Config - $key: $value');
      });
    }
  }
}
```

This comprehensive debugging guide covers all aspects of Flutter development for the ASTU-Q app, from basic logging to advanced performance monitoring and error handling.
