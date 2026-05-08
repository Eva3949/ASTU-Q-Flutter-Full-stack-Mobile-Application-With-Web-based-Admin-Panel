# Common Flutter Errors and Fixes for ASTU-Q App

This guide covers the most common Flutter errors encountered during development and their solutions, specifically tailored for the ASTU-Q application.

## 1. Build and Compilation Errors

### Error: "Target of URI doesn't exist"
**Problem**: Import statement references a file that doesn't exist
```dart
// Error
import 'package:dio/dio.dart';  // Package not installed
import '../utils/logger.dart';  // File doesn't exist
```

**Solution**:
```bash
# Install missing packages
flutter pub add dio
flutter pub add provider
flutter pub add shared_preferences
flutter pub add flutter_screenutil
flutter pub add image_picker
flutter pub add fl_chart

# Create missing files manually or use templates
touch lib/core/utils/logger.dart
touch lib/core/themes/colors.dart
touch lib/core/themes/text_styles.dart
```

### Error: "Undefined class 'ClassName'"
**Problem**: Class not imported or doesn't exist
```dart
// Error
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return QuestionCardWidget(question: question); // Class not found
  }
}
```

**Solution**:
```dart
// Add proper import
import '../shared/widgets/question_card_widget.dart';

class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return QuestionCardWidget(question: question);
  }
}
```

### Error: "The named parameter 'parameterName' is required"
**Problem**: Missing required parameter in constructor
```dart
// Error
SessionInfo(
  hasToken: true,
  hasRefreshToken: true,
  // Missing required parameters
);
```

**Solution**:
```dart
SessionInfo(
  hasToken: true,
  hasRefreshToken: true,
  hasUserData: true,
  sessionTimeoutMinutes: 30,
  rememberMe: false,
  biometricEnabled: false,
  isValid: true,
);
```

## 2. Runtime Errors

### Error: "NoSuchMethodError: The method 'methodName' was called on null"
**Problem**: Calling method on null object
```dart
// Error
String? name;
print(name.length); // Throws NoSuchMethodError
```

**Solution**:
```dart
// Option 1: Null check
String? name;
if (name != null) {
  print(name.length);
}

// Option 2: Null-aware operator
String? name;
print(name?.length ?? 0);

// Option 3: Assert non-null
String name = getName()!; // Use ! when you're sure it's not null
print(name.length);
```

### Error: "RangeError: Index out of range"
**Problem**: Accessing array index that doesn't exist
```dart
// Error
List<String> items = ['a', 'b', 'c'];
print(items[5]); // Throws RangeError
```

**Solution**:
```dart
// Check bounds before access
List<String> items = ['a', 'b', 'c'];
if (items.length > 5) {
  print(items[5]);
} else {
  print('Index out of range');
}

// Or use safe access
print(items.isNotEmpty ? items[0] : 'No items');
```

### Error: "FormatException: Invalid number format"
**Problem**: Parsing invalid string to number
```dart
// Error
int number = int.parse('abc'); // Throws FormatException
```

**Solution**:
```dart
// Use tryParse instead of parse
String text = '123';
int? number = int.tryParse(text);
if (number != null) {
  print('Parsed number: $number');
} else {
  print('Invalid number format');
}
```

## 3. State Management Errors

### Error: "Provider not found"
**Problem**: Trying to access Provider that's not in widget tree
```dart
// Error
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // Provider not found above this widget
  }
}
```

**Solution**:
```dart
// Wrap app with Provider
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => QuestionProvider()),
      ],
      child: MyApp(),
    ),
  );
}

// Or use Consumer/Selector
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Text('User: ${authProvider.user?.name}');
      },
    );
  }
}
```

### Error: "setState() called after dispose()"
**Problem**: Calling setState on disposed widget
```dart
// Error
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(seconds: 1), () {
      setState(() {}); // Might be called after dispose
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Important: cancel timers
    super.dispose();
  }
}
```

**Solution**:
```dart
class _MyWidgetState extends State<MyWidget> {
  Timer? _timer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(seconds: 1), () {
      if (!_disposed) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
```

## 4. Navigation Errors

### Error: "Navigator operation requested with a context that does not include a Navigator"
**Problem**: Using context that doesn't have Navigator in widget tree
```dart
// Error
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(...)); // Context doesn't have Navigator
      },
      child: Text('Navigate'),
    );
  }
}
```

**Solution**:
```dart
// Option 1: Use Builder widget
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(...));
          },
          child: Text('Navigate'),
        );
      },
    );
  }
}

// Option 2: Use navigator key
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(...),
        );
      },
      child: Text('Navigate'),
    );
  }
}
```

### Error: "Could not find a generator for route RouteSettings"
**Problem**: Route not defined in MaterialApp
```dart
// Error
Navigator.pushNamed(context, '/undefined_route'); // Route not defined
```

**Solution**:
```dart
MaterialApp(
  routes: {
    '/': (context) => HomeScreen(),
    '/questions': (context) => QuestionsScreen(),
    '/profile': (context) => ProfileScreen(),
    // Add all routes
  },
  onGenerateRoute: (settings) {
    // Handle dynamic routes
    if (settings.name?.startsWith('/questions/') == true) {
      final questionId = int.parse(settings.name!.split('/').last);
      return MaterialPageRoute(
        builder: (context) => QuestionDetailScreen(questionId: questionId),
      );
    }
    return null;
  },
)
```

## 5. Network Errors

### Error: "SocketException: Connection refused"
**Problem**: Network connection issues
```dart
// Error
final response = await http.get(Uri.parse('http://localhost:3000/api')); // Server not running
```

**Solution**:
```dart
// Add proper error handling and configuration
class ApiService {
  static const String baseUrl = 'https://api.astuq.app'; // Use production URL
  
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
```

### Error: "HTTP 401 Unauthorized"
**Problem**: Authentication token missing or invalid
```dart
// Error
final response = await http.get(Uri.parse('$baseUrl/questions')); // No auth header
```

**Solution**:
```dart
class AuthenticatedApiService {
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final token = await SecureStorage().getToken();
    
    if (token == null) {
      throw Exception('No authentication token');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 401) {
      // Token expired, refresh or logout
      await AuthManager().logout();
      throw Exception('Session expired');
    }
    
    return jsonDecode(response.body);
  }
}
```

## 6. UI and Layout Errors

### Error: "RenderFlex overflowed by X pixels"
**Problem**: Widget content exceeds available space
```dart
// Error
Row(
  children: [
    Container(width: 200, child: Text('Very long text...')),
    Container(width: 200, child: Text('Another long text...')),
  ],
) // Overflows if screen width < 400
```

**Solution**:
```dart
// Option 1: Use Flexible or Expanded
Row(
  children: [
    Expanded(child: Text('Very long text...')),
    Expanded(child: Text('Another long text...')),
  ],
)

// Option 2: Use Wrap widget
Wrap(
  children: [
    Container(child: Text('Very long text...')),
    Container(child: Text('Another long text...')),
  ],
)

// Option 3: Use SingleChildScrollView
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      Container(width: 200, child: Text('Very long text...')),
      Container(width: 200, child: Text('Another long text...')),
    ],
  ),
)
```

### Error: "BoxConstraints forces an infinite height"
**Problem**: Widget with infinite height constraint
```dart
// Error
Column(
  children: [
    Expanded(
      child: ListView.builder(...), // ListView in Column without constraints
    ),
  ],
)
```

**Solution**:
```dart
// Option 1: Use Expanded with Flexible
Column(
  children: [
    Flexible(
      child: ListView.builder(...),
    ),
  ],
)

// Option 2: Use ListView with shrinkWrap
Column(
  children: [
    ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => ListTile(...),
    ),
  ],
)

// Option 3: Use CustomScrollView
CustomScrollView(
  slivers: [
    SliverToBoxAdapter(child: HeaderWidget()),
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => ListTile(...),
      ),
    ),
  ],
)
```

## 7. Form Validation Errors

### Error: "Form validation not working"
**Problem**: Form key not properly configured
```dart
// Error
class MyForm extends StatefulWidget {
  @override
  _MyFormState createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            validator: (value) {
              if (value?.isEmpty == true) {
                return 'Required field';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() == true) {
                // Form is valid
              }
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}
```

**Solution**:
```dart
class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction, // Add this
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Email',
              errorStyle: TextStyle(color: Colors.red),
            ),
            validator: (value) {
              if (value?.isEmpty == true) {
                return 'Email is required';
              }
              if (!value!.contains('@')) {
                return 'Invalid email format';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() == true) {
                _formKey.currentState?.save();
                // Process form data
              }
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}
```

## 8. Image and Asset Errors

### Error: "Unable to load asset"
**Problem**: Asset path incorrect or not declared in pubspec.yaml
```dart
// Error
Image.asset('assets/images/logo.png'); // Asset not found
```

**Solution**:
```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
    - assets/data/
```

```dart
// Correct usage
Image.asset('assets/images/logo.png');

// Or use AssetImage
Image(image: AssetImage('assets/images/logo.png'));
```

### Error: "NetworkImage failed to load"
**Problem**: Network image loading issues
```dart
// Error
Image.network('https://example.com/image.jpg'); // Network error
```

**Solution**:
```dart
Image.network(
  'https://example.com/image.jpg',
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
            : null,
      ),
    );
  },
  errorBuilder: (context, error, stackTrace) {
    return Container(
      color: Colors.grey[300],
      child: Icon(Icons.error),
    );
  },
)
```

## 9. Async/Await Errors

### Error: "Future<void> can't be assigned to void"
**Problem**: Incorrect async function usage
```dart
// Error
void myFunction() {
  Future.delayed(Duration(seconds: 1)); // Returns Future, not void
}
```

**Solution**:
```dart
// Option 1: Make function async
Future<void> myFunction() async {
  await Future.delayed(Duration(seconds: 1));
}

// Option 2: Handle Future without await
void myFunction() {
  Future.delayed(Duration(seconds: 1)).then((_) {
    print('Delayed action completed');
  });
}

// Option 3: Use unawaited (if you don't care about result)
import 'dart:async';

void myFunction() {
  unawaited(Future.delayed(Duration(seconds: 1)));
}
```

### Error: "Unhandled Promise rejection"
**Problem:**
```dart
// Error
Future<void> myFunction() async {
  throw Exception('Something went wrong'); // Unhandled exception
}

void main() {
  myFunction(); // Exception not caught
}
```

**Solution**:
```dart
// Option 1: Try-catch
Future<void> myFunction() async {
  try {
    // async operations
  } catch (e) {
    print('Error: $e');
  }
}

// Option 2: Handle at call site
void main() async {
  try {
    await myFunction();
  } catch (e) {
    print('Error: $e');
  }
}

// Option 3: Use catchError
void main() {
  myFunction().catchError((e) => print('Error: $e'));
}
```

## 10. Platform-Specific Errors

### Error: "MissingPluginException"
**Problem**: Plugin not properly installed or platform-specific code missing
```dart
// Error
import 'package:image_picker/image_picker.dart';
final picker = ImagePicker();
final image = await picker.getImage(source: ImageSource.camera); // Plugin not found
```

**Solution**:
```bash
# Reinstall plugin
flutter pub add image_picker
flutter pub get

# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check platform-specific configuration
# Android: android/app/src/main/AndroidManifest.xml
# iOS: ios/Runner/Info.plist
```

### Error: "PlatformException (PlatformException(...))"
**Problem**: Platform-specific operation failed
```dart
// Error
import 'package:shared_preferences/shared_preferences.dart';
final prefs = await SharedPreferences.getInstance();
final value = prefs.getString('key'); // Platform exception
```

**Solution**:
```dart
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getValue(String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  } on PlatformException catch (e) {
    print('Platform error: $e');
    return null;
  } catch (e) {
    print('Unexpected error: $e');
    return null;
  }
}
```

## 11. Performance Issues

### Error: "Excessive build time"
**Problem**: Widget rebuilding too frequently
```dart
// Error
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 1000,
      itemBuilder: (context, index) {
        return HeavyWidget(index: index); // Rebuilds all items
      },
    );
  }
}
```

**Solution**:
```dart
// Option 1: Use const constructors
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 1000,
      itemBuilder: (context, index) {
        return HeavyWidget(index: index); // Make HeavyWidget const if possible
      },
    );
  }
}

// Option 2: Use AutomaticKeepAliveClientMixin
class HeavyWidget extends StatefulWidget {
  final int index;
  
  const HeavyWidget({Key? key, required this.index}) : super(key: key);
  
  @override
  _HeavyWidgetState createState() => _HeavyWidgetState();
}

class _HeavyWidgetState extends State<HeavyWidget> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Container(
      child: Text('Item ${widget.index}'),
    );
  }
}
```

## 12. Memory Leaks

### Error: "Memory leak detected"
**Problem**: Objects not properly disposed
```dart
// Error
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  StreamSubscription? _subscription;
  Timer? _timer;
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _subscription = someStream.listen((data) {});
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {});
    _controller = AnimationController(vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
  // Missing dispose() - memory leak!
}
```

**Solution**:
```dart
class _MyWidgetState extends State<MyWidget> with TickerProviderStateMixin {
  StreamSubscription? _subscription;
  Timer? _timer;
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _subscription = someStream.listen((data) {});
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {});
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

## 13. Quick Fix Checklist

### Before Running App
```bash
# 1. Clean and get dependencies
flutter clean
flutter pub get

# 2. Check for missing imports
flutter analyze

# 3. Run tests
flutter test

# 4. Check formatting
dart format --set-exit-if-changed .
```

### Common Debug Commands
```bash
# Check device connection
flutter devices

# Run with verbose logging
flutter run -v

# Check for issues
flutter doctor

# Analyze code
flutter analyze

# Build for different platforms
flutter build apk --debug
flutter build ios --debug
```

### Environment Setup
```bash
# Check Flutter version
flutter --version

# Update Flutter
flutter upgrade

# Check connected devices
flutter devices

# Run on specific device
flutter run -d <device_id>
```

This comprehensive guide covers the most common Flutter errors and their solutions, providing practical fixes for the ASTU-Q application development.
