import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  // Карта приложений — название → package
  static const Map<String, String> _apps = {
    'telegram': 'org.telegram.messenger',
    'whatsapp': 'com.whatsapp',
    'youtube': 'com.google.android.youtube',
    'instagram': 'com.instagram.android',
    'tiktok': 'com.zhiliaoapp.musically',
    'chrome': 'com.android.chrome',
    'firefox': 'org.mozilla.firefox',
    'camera': 'com.android.camera2',
    'gallery': 'com.google.android.apps.photos',
    'photos': 'com.google.android.apps.photos',
    'maps': 'com.google.android.apps.maps',
    'гугл карты': 'com.google.android.apps.maps',
    'карты': 'com.google.android.apps.maps',
    'music': 'com.google.android.music',
    'spotify': 'com.spotify.music',
    'settings': 'com.android.settings',
    'настройки': 'com.android.settings',
    'calculator': 'com.android.calculator2',
    'калькулятор': 'com.android.calculator2',
    'calendar': 'com.google.android.calendar',
    'календарь': 'com.google.android.calendar',
    'clock': 'com.google.android.deskclock',
    'часы': 'com.google.android.deskclock',
    'gmail': 'com.google.android.gm',
    'vk': 'com.vkontakte.android',
    'вк': 'com.vkontakte.android',
    'вконтакте': 'com.vkontakte.android',
    'twitter': 'com.twitter.android',
    'x': 'com.twitter.android',
    'facebook': 'com.facebook.katana',
    'zoom': 'us.zoom.videomeetings',
    'discord': 'com.discord',
    'snapchat': 'com.snapchat.android',
    'netflix': 'com.netflix.mediaclient',
    'play market': 'com.android.vending',
    'плей маркет': 'com.android.vending',
    'магазин': 'com.android.vending',
    'files': 'com.google.android.documentsui',
    'файлы': 'com.google.android.documentsui',
    'contacts': 'com.google.android.contacts',
    'контакты': 'com.google.android.contacts',
    'phone': 'com.google.android.dialer',
    'телефон': 'com.google.android.dialer',
    'messages': 'com.google.android.apps.messaging',
    'смс': 'com.google.android.apps.messaging',
    'сообщения': 'com.google.android.apps.messaging',
  };

  static const MethodChannel _channel = MethodChannel('singula/launcher');

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
        onNavigationRequest: (request) => NavigationDecision.navigate,
      ))
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (msg) => _handleCommand(msg.message),
      )
      ..loadFlutterAsset('assets/singula.html');
  }

  Future<void> _handleCommand(String command) async {
    final cmd = command.toLowerCase().trim();
    String result = 'Команда получена';

    try {
      // ЗВОНОК
      if (cmd.contains('позвони') || cmd.contains('call')) {
        final number = cmd.replaceAll(RegExp(r'[^0-9+]'), '');
        if (number.isNotEmpty) {
          await _launchUrl('tel:$number');
          result = 'Звоню на $number';
        }
      }
      // СМС
      else if (cmd.contains('смс') || cmd.contains('сообщение') || cmd.contains('напиши')) {
        await _launchUrl('sms:');
        result = 'Открываю сообщения';
      }
      // YOUTUBE с поиском
      else if (cmd.contains('youtube') || cmd.contains('ютуб') || cmd.contains('ютьюб')) {
        String query = cmd
            .replaceAll('открой', '').replaceAll('включи', '')
            .replaceAll('youtube', '').replaceAll('ютуб', '').replaceAll('ютьюб', '')
            .replaceAll('выполняй', '').trim();
        if (query.isNotEmpty) {
          final encoded = Uri.encodeComponent(query);
          final launched = await _launchUrl('vnd.youtube://results?search_query=$encoded');
          if (!launched) await _launchUrl('https://www.youtube.com/results?search_query=$encoded');
          result = 'Открываю YouTube: $query';
        } else {
          final launched = await _launchUrl('vnd.youtube://');
          if (!launched) await _launchUrl('https://youtube.com');
          result = 'Открываю YouTube';
        }
      }
      // ПОИСК в браузере
      else if (cmd.contains('найди') || cmd.contains('поищи') || cmd.contains('загугли')) {
        String query = cmd
            .replaceAll('найди', '').replaceAll('поищи', '').replaceAll('загугли', '')
            .replaceAll('выполняй', '').trim();
        final encoded = Uri.encodeComponent(query);
        await _launchUrl('https://www.google.com/search?q=$encoded');
        result = 'Ищу: $query';
      }
      // ОТКРЫТЬ ПРИЛОЖЕНИЕ по названию
      else {
        String? packageName;
        String? foundName;
        for (final entry in _apps.entries) {
          if (cmd.contains(entry.key)) {
            packageName = entry.value;
            foundName = entry.key;
            break;
          }
        }
        if (packageName != null) {
          final launched = await _launchUrl('android-app://$packageName');
          if (!launched) {
            await _launchUrl('market://details?id=$packageName');
          }
          result = 'Открываю $foundName';
        } else {
          HapticFeedback.mediumImpact();
          result = 'Выполнено';
        }
      }
    } catch (e) {
      result = 'Ошибка: $e';
    }

    HapticFeedback.lightImpact();
    _controller.runJavaScript(
      "if(window.onFlutterResponse) window.onFlutterResponse('$result')"
    );
  }

  Future<bool> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      // Используем Intent через platform channel
      final result = await _channel.invokeMethod<bool>('launch', {'url': url});
      return result ?? false;
    } catch (e) {
      // Fallback — пробуем через обычный Intent
      try {
        await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      } catch (_) {}
      return false;
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
                      const Text('SINGULA',
                        style: TextStyle(
                          color: Color(0xFFF0C040), fontSize: 32,
                          fontWeight: FontWeight.bold, letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(width: 40, height: 40,
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
