import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/navigation/app_router.dart';
import 'core/navigation/app_routes.dart';
import 'core/themes/app_theme.dart';
import 'core/di/injection_container.dart';
import 'features/authentication/presentation/providers/authentication_provider.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/questions/presentation/providers/question_provider.dart';
import 'features/questions/presentation/providers/simple_question_provider.dart';
import 'features/leaderboard/presentation/providers/leaderboard_provider.dart';
import 'features/ai_chat/presentation/providers/ai_provider.dart';
import 'core/notifications/notification_service.dart';
import 'package:workmanager/workmanager.dart';
import 'core/notifications/background_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();

  // Initialize Notification Service
  await sl<NotificationService>().initialize();

  // Initialize Workmanager for background notifications
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  // Register periodic task (every 15 minutes - minimum allowed by Android)
  Workmanager().registerPeriodicTask(
    "notification_polling_task",
    "fetch_notifications",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ASTUQApp());
}

class ASTUQApp extends StatelessWidget {
  const ASTUQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => sl<AuthenticationProvider>()),
        ChangeNotifierProvider(create: (_) => sl<SimpleQuestionProvider>()),
        ChangeNotifierProvider(create: (_) => sl<QuestionProvider>()),
        ChangeNotifierProvider(create: (_) => sl<LeaderboardProvider>()),
        ChangeNotifierProvider(create: (_) => sl<NotificationProvider>()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
        ChangeNotifierProvider(create: (_) => sl<ChatProvider>()),
      ],
      child: MaterialApp(
        title: 'ASTU-Q',
        debugShowCheckedModeBanner: false,
        navigatorKey: AppRouter.navigatorKey,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRoutes.splash,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0, // Prevent text scaling
            ),
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(
                physics: BouncingScrollPhysics(),
                overscroll: false,
              ),
              child: child!,
            ),
          );
        },
      ),
    );
  }
}
