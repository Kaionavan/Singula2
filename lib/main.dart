import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF020810),
  ));
  runApp(const SingulaApp());
}

class SingulaApp extends StatelessWidget {
  const SingulaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SINGULA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8A84B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SingulaScreen(),
    );
  }
}

class SingulaScreen extends StatefulWidget {
  const SingulaScreen({super.key});
  @override
  State<SingulaScreen> createState() => _SingulaScreenState();
}

class _SingulaScreenState extends State<SingulaScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF020810))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _isLoading = false),
      ))
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (msg) => _handleCommand(msg.message),
      )
      ..loadFlutterAsset('assets/singula.html');
  }

  Future<void> _handleCommand(String command) async {
    final cmd = command.toLowerCase().trim();

    if (cmd.contains('telegram')) {
      _launch('tg://');
    } else if (cmd.contains('whatsapp')) {
      _launch('whatsapp://');
    } else if (cmd.contains('youtube')) {
      _launch('https://youtube.com');
    } else if (cmd.contains('instagram')) {
      _launch('instagram://');
    } else if (cmd.contains('play market') || cmd.contains('плей маркет')) {
      _launch('market://');
    } else if (cmd.contains('браузер') || cmd.contains('browser') || cmd.contains('гугл') || cmd.contains('google')) {
      _launch('https://google.com');
    } else if (cmd.contains('настройки') || cmd.contains('settings')) {
      _launch('android-app://com.android.settings');
    } else if (cmd.startsWith('позвони') || cmd.startsWith('call')) {
      final number = cmd.replaceAll(RegExp(r'[^0-9+]'), '');
      if (number.isNotEmpty) _launch('tel:$number');
    } else if (cmd.contains('сообщение') || cmd.contains('смс')) {
      _launch('sms:');
    } else {
      HapticFeedback.mediumImpact();
    }

    _controller.runJavaScript(
      "if(window.onFlutterResponse) window.onFlutterResponse('Выполнено: $command')"
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Launch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020810),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: const Color(0xFF020810),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'SINGULA',
                        style: TextStyle(
                          color: Color(0xFFF0C040),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(
                        width: 40, height: 40,
                        child: CircularProgressIndicator(
                          color: Color(0xFF4AB0FF),
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ИНИЦИАЛИЗАЦИЯ...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
