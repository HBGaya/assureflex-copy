import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'core/services/notification_service.dart';
import 'core/services/auth_storage.dart';
import 'core/theme/app_theme.dart';

import './presentation/screens/auth/login_screen.dart';
import './presentation/screens/auth/register_screen.dart';
import './presentation/screens/auth/forgot_password_screen.dart';
import './presentation/screens/claim_form/claim_form.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      title: 'Auth App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const VideoSplashGate(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/form': (context) => const ClaimForm(),
      },
    );
  }
}

/// Splash that plays an MP4 once, then applies the same auth routing:
/// if token exists -> '/form', else -> '/login'.
class VideoSplashGate extends StatefulWidget {
  const VideoSplashGate({Key? key}) : super(key: key);

  @override
  State<VideoSplashGate> createState() => _VideoSplashGateState();
}

class _VideoSplashGateState extends State<VideoSplashGate> {
  late final VideoPlayerController _controller;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _initNotificationsAsync();
  }
  Future<void> _initNotificationsAsync() async {
    try {
      await NotificationService.I.init().timeout(
        const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  Future<void> _bootstrap() async {
    _controller = VideoPlayerController.asset('assets/splash.mp4');

    // Add the listener early
    _controller.addListener(_onTick);

    await _controller.initialize();
    if (!mounted) return;

    // <<< CRITICAL: trigger rebuild so we swap spinner -> video
    setState(() {});

    _controller.setLooping(false);
    _controller.setVolume(0);
    _controller.play();
  }

  void _onTick() {
    if (!mounted) return;
    final v = _controller.value;

    // Optional: if you want progress UI updates (not required),
    // you could throttle setState here.

    // Handle errors
    if (v.hasError && !_navigated) {
      _navigated = true;
      _decideNext();
      return;
    }

    // Detect end (with a little tolerance)
    if (v.isInitialized &&
        !v.isPlaying &&
        v.duration != null &&
        v.position >= (v.duration - const Duration(milliseconds: 200)) &&
        !_navigated) {
      _navigated = true;
      _decideNext();
    }
  }

  Future<void> _decideNext() async {
    final token = await AuthStorage.read();
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed('/form');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_controller.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
