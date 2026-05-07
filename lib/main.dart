import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/quiz_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isMacOS || Platform.isWindows) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      title: 'Quiz Buzzer',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: QuizBuzzerApp()));
}

class SoundService {
  static void playBuzz() {
    if (Platform.isMacOS) {
      Process.run('say', ['Go!', '-v', 'OK']);
    }
  }

  static void playWin() async {
    if (Platform.isMacOS) {
      await Process.run('afplay', ['/System/Library/Sounds/Glass.aiff']);
    }
  }

  static void playCountdown() {
    if (Platform.isMacOS) {
      Process.run('afplay', ['/System/Library/Sounds/Tink.aiff']);
    }
  }

  static void playJoin() {
    if (Platform.isMacOS) {
      Process.run('afplay', ['/System/Library/Sounds/Pop.aiff']);
    }
  }
}

class QuizBuzzerApp extends StatelessWidget {
  const QuizBuzzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Buzzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF58A6FF),
          brightness: Brightness.dark,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF161B22),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF238636),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF21262D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isLoading = false;
  String? _prevWinner;

  Future<void> _startServer(int port, int maxParticipants, int timerSeconds) async {
    final assetsPath = _getAssetsPath();
    setState(() => _isLoading = true);
    try {
      final settings = QuizSettings(
        maxParticipants: maxParticipants,
        timerSeconds: timerSeconds,
      );
      await ref.read(quizProvider.notifier).startServer(port, assetsPath, settings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getAssetsPath() {
    if (Platform.isAndroid || Platform.isIOS) {
      return 'web';
    }
    return '/Users/macbook/Downloads/raisehand/web';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizProvider);

    if (state.error != null && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
        }
      });
    }

    return Scaffold(
      body: state.isServerRunning
          ? const DashboardScreen()
          : SetupScreen(onStartServer: _startServer, isLoading: _isLoading),
    );
  }
}