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
        onNavigationRequest: (r) => NavigationDecision.navigate,
      ))
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (msg) => _handleCommand(msg.message),
      )
      ..loadFlutterAsset('assets/singula.html');
  }

  // Карта приложений
  static const Map<String, String> _packages = {
    'telegram': 'org.telegram.messenger',
    'whatsapp': 'com.whatsapp',
    'youtube': 'com.google.android.youtube',
    'ютуб': 'com.google.android.youtube',
    'instagram': 'com.instagram.android',
    'tiktok': 'com.zhiliaoapp.musically',
    'тикток': 'com.zhiliaoapp.musically',
    'vk': 'com.vkontakte.android',
    'вк': 'com.vkontakte.android',
    'вконтакте': 'com.vkontakte.android',
    'discord': 'com.discord',
    'spotify': 'com.spotify.music',
    'netflix': 'com.netflix.mediaclient',
    'zoom': 'us.zoom.videomeetings',
    'gmail': 'com.google.android.gm',
    'maps': 'com.google.android.apps.maps',
    'карты': 'com.google.android.apps.maps',
    'camera': 'com.android.camera2',
    'камера': 'com.android.camera2',
    'calculator': 'com.android.calculator2',
    'калькулятор': 'com.android.calculator2',
    'calendar': 'com.google.android.calendar',
    'календарь': 'com.google.android.calendar',
    'clock': 'com.google.android.deskclock',
    'часы': 'com.google.android.deskclock',
    'settings': 'com.android.settings',
    'настройки': 'com.android.settings',
    'play market': 'com.android.vending',
    'плей маркет': 'com.android.vending',
    'магазин': 'com.android.vending',
    'файлы': 'com.google.android.documentsui',
    'контакты': 'com.google.android.contacts',
    'twitter': 'com.twitter.android',
    'snapchat': 'com.snapchat.android',
    'facebook': 'com.facebook.katana',
  };

  Future<void> _handleCommand(String command) async {
    final cmd = command.toLowerCase().trim();
    String result = 'Выполнено';

    try {
      // ЗВОНОК
      if (cmd.contains('позвони') || cmd.startsWith('call')) {
        final number = cmd.replaceAll(RegExp(r'[^0-9+]'), '');
        if (number.isNotEmpty) {
          await launchUrl(Uri.parse('tel:$number'),
              mode: LaunchMode.externalApplication);
          result = 'Звоню: $number';
        }
      }
      // СМС
      else if (cmd.contains('смс') || cmd.contains('напиши сообщение')) {
        await launchUrl(Uri.parse('sms:'),
            mode: LaunchMode.externalApplication);
        result = 'Открываю сообщения';
      }
      // YOUTUBE с поиском
      else if (cmd.contains('youtube') || cmd.contains('ютуб')) {
        String query = cmd
            .replaceAll(RegExp(r'открой|включи|запусти|youtube|ютуб|выполняй'), '')
            .trim();
        if (query.isNotEmpty) {
          final enc = Uri.encodeComponent(query);
          bool ok = await launchUrl(
            Uri.parse('vnd.youtube://results?search_query=$enc'),
            mode: LaunchMode.externalApplication,
          );
          if (!ok) {
            await launchUrl(
              Uri.parse('https://www.youtube.com/results?search_query=$enc'),
              mode: LaunchMode.externalApplication,
            );
          }
          result = 'Открываю YouTube: $query';
        } else {
          bool ok = await launchUrl(Uri.parse('vnd.youtube://'),
              mode: LaunchMode.externalApplication);
          if (!ok) {
            await launchUrl(Uri.parse('https://youtube.com'),
                mode: LaunchMode.externalApplication);
          }
          result = 'Открываю YouTube';
        }
      }
      // ПОИСК В ГУГЛ
      else if (cmd.contains('найди') ||
          cmd.contains('поищи') ||
          cmd.contains('загугли') ||
          cmd.contains('поиск')) {
        String query = cmd
            .replaceAll(RegExp(r'найди|поищи|загугли|поиск|выполняй'), '')
            .trim();
        final enc = Uri.encodeComponent(query);
        await launchUrl(
          Uri.parse('https://www.google.com/search?q=$enc'),
          mode: LaunchMode.externalApplication,
        );
        result = 'Ищу: $query';
      }
      // ОТКРЫТЬ ПРИЛОЖЕНИЕ
      else {
        String? pkg;
        String? name;
        for (final e in _packages.entries) {
          if (cmd.contains(e.key)) {
            pkg = e.value;
            name = e.key;
            break;
          }
        }
        if (pkg != null) {
          bool ok = await launchUrl(
            Uri.parse('android-app://$pkg'),
            mode: LaunchMode.externalApplication,
          );
          if (!ok) {
            // Не установлено — в Play Market
            await launchUrl(
              Uri.parse('https://play.google.com/store/apps/details?id=$pkg'),
              mode: LaunchMode.externalApplication,
            );
            result = 'Приложение не найдено, открываю Play Market';
          } else {
            result = 'Открываю $name';
          }
        } else {
          HapticFeedback.mediumImpact();
        }
      }
    } catch (e) {
      result = 'Ошибка запуска';
    }

    HapticFeedback.lightImpact();
    final safe = result.replaceAll("'", "\\'");
    _controller.runJavaScript(
      "if(window.onFlutterResponse) window.onFlutterResponse('$safe')",
    );
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
                      const Text('SINGULA',
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
                          color: Color(0xFF4AB0FF), strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('ИНИЦИАЛИЗАЦИЯ...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11, letterSpacing: 4,
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
