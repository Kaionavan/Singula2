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

  // Извлечь текст после ключевых слов
  String _extract(String cmd, List<String> keywords) {
    String result = cmd;
    for (final k in keywords) {
      result = result.replaceAll(k, '');
    }
    return result
        .replaceAll(RegExp(r'открой|открыть|запусти|включи|включить|выполняй|сингула|напиши|найди|поищи|покажи|поставь|воспроизведи'), '')
        .trim();
  }

  Future<void> _handleCommand(String raw) async {
    final cmd = raw.toLowerCase().trim();
    String result = 'Выполнено';

    try {
      // ══ ЗВОНОК ══
      if (cmd.contains('позвони') || cmd.contains('звони') || cmd.contains('набери')) {
        final number = cmd.replaceAll(RegExp(r'[^0-9+]'), '');
        if (number.isNotEmpty) {
          await _open('tel:$number');
          result = 'Звоню: $number';
        } else {
          await _open('tel:');
          result = 'Открываю телефон';
        }
      }

      // ══ WHATSAPP ══
      else if (cmd.contains('whatsapp') || cmd.contains('вотсап') || cmd.contains('ватсап')) {
        final number = cmd.replaceAll(RegExp(r'[^0-9+]'), '');
        final text = _extract(cmd, ['whatsapp', 'вотсап', 'ватсап', 'напиши', 'отправь']);
        if (number.isNotEmpty) {
          final enc = Uri.encodeComponent(text);
          await _open('https://wa.me/$number?text=$enc');
        } else if (text.isNotEmpty) {
          final enc = Uri.encodeComponent(text);
          await _open('whatsapp://send?text=$enc');
        } else {
          await _open('whatsapp://');
        }
        result = 'Открываю WhatsApp';
      }

      // ══ TELEGRAM ══
      else if (cmd.contains('telegram') || cmd.contains('телеграм') || cmd.contains('телегу')) {
        final username = RegExp(r'@(\w+)').firstMatch(cmd)?.group(1);
        final text = _extract(cmd, ['telegram', 'телеграм', 'телегу', 'напиши', 'открой']);
        if (username != null) {
          await _open('tg://resolve?domain=$username');
          result = 'Открываю @$username в Telegram';
        } else if (text.isNotEmpty && !text.contains('телеграм')) {
          await _open('tg://msg?text=${Uri.encodeComponent(text)}');
          result = 'Открываю Telegram';
        } else {
          await _open('tg://');
        }
        result = 'Открываю Telegram';
      }

      // ══ YOUTUBE ══
      else if (cmd.contains('youtube') || cmd.contains('ютуб') || cmd.contains('ютьюб')) {
        final query = _extract(cmd, ['youtube', 'ютуб', 'ютьюб']);
        if (query.isNotEmpty) {
          final enc = Uri.encodeComponent(query);
          bool ok = await _open('vnd.youtube://results?search_query=$enc');
          if (!ok) await _open('https://www.youtube.com/results?search_query=$enc');
          result = 'Ищу на YouTube: $query';
        } else {
          bool ok = await _open('vnd.youtube://');
          if (!ok) await _open('https://youtube.com');
          result = 'Открываю YouTube';
        }
      }

      // ══ SPOTIFY ══
      else if (cmd.contains('spotify') || cmd.contains('спотифай')) {
        final query = _extract(cmd, ['spotify', 'спотифай']);
        if (query.isNotEmpty) {
          final enc = Uri.encodeComponent(query);
          bool ok = await _open('spotify:search:$query');
          if (!ok) await _open('https://open.spotify.com/search/$enc');
          result = 'Ищу в Spotify: $query';
        } else {
          await _open('spotify://');
          result = 'Открываю Spotify';
        }
      }

      // ══ ЗВУК КЛАУД / SOUNDCLOUD ══
      else if (cmd.contains('soundcloud') || cmd.contains('саунд клауд') || cmd.contains('soundcloud') || cmd.contains('саундклауд')) {
        final query = _extract(cmd, ['soundcloud', 'саунд клауд', 'саундклауд']);
        if (query.isNotEmpty) {
          final enc = Uri.encodeComponent(query);
          await _open('https://soundcloud.com/search?q=$enc');
          result = 'Ищу в SoundCloud: $query';
        } else {
          await _open('https://soundcloud.com');
          result = 'Открываю SoundCloud';
        }
      }

      // ══ INSTAGRAM ══
      else if (cmd.contains('instagram') || cmd.contains('инстаграм') || cmd.contains('инста')) {
        final username = RegExp(r'@(\w+)').firstMatch(cmd)?.group(1);
        if (username != null) {
          bool ok = await _open('instagram://user?username=$username');
          if (!ok) await _open('https://instagram.com/$username');
          result = 'Открываю @$username в Instagram';
        } else {
          await _open('instagram://');
          result = 'Открываю Instagram';
        }
      }

      // ══ TIKTOK ══
      else if (cmd.contains('tiktok') || cmd.contains('тикток')) {
        final query = _extract(cmd, ['tiktok', 'тикток']);
        if (query.isNotEmpty) {
          await _open('https://www.tiktok.com/search?q=${Uri.encodeComponent(query)}');
          result = 'Ищу в TikTok: $query';
        } else {
          await _open('snssdk1233://');
          result = 'Открываю TikTok';
        }
      }

      // ══ VK ══
      else if (cmd.contains('вконтакте') || cmd.contains('вк') || cmd.contains('vk')) {
        final query = _extract(cmd, ['вконтакте', 'вк', 'vk']);
        if (query.isNotEmpty) {
          await _open('https://vk.com/search?c[q]=${Uri.encodeComponent(query)}');
        } else {
          bool ok = await _open('vk://');
          if (!ok) await _open('https://vk.com');
        }
        result = 'Открываю ВКонтакте';
      }

      // ══ GOOGLE MAPS ══
      else if (cmd.contains('карты') || cmd.contains('maps') || cmd.contains('маршрут') || cmd.contains('навигация')) {
        final dest = _extract(cmd, ['карты', 'maps', 'маршрут', 'навигация', 'проложи', 'до', 'едем']);
        if (dest.isNotEmpty) {
          final enc = Uri.encodeComponent(dest);
          bool ok = await _open('geo:0,0?q=$enc');
          if (!ok) await _open('https://maps.google.com/?q=$enc');
          result = 'Прокладываю маршрут до $dest';
        } else {
          await _open('geo:0,0');
          result = 'Открываю Карты';
        }
      }

      // ══ GMAIL ══
      else if (cmd.contains('gmail') || cmd.contains('почта') || cmd.contains('email')) {
        final query = _extract(cmd, ['gmail', 'почта', 'email', 'напиши']);
        if (query.isNotEmpty) {
          await _open('mailto:?body=${Uri.encodeComponent(query)}');
        } else {
          bool ok = await _open('googlegmail://');
          if (!ok) await _open('https://gmail.com');
        }
        result = 'Открываю Gmail';
      }

      // ══ КАМЕРА ══
      else if (cmd.contains('камера') || cmd.contains('camera') || cmd.contains('сними') || cmd.contains('сфотографируй')) {
        await _open('android.media.action.IMAGE_CAPTURE');
        result = 'Открываю камеру';
      }

      // ══ НАСТРОЙКИ ══
      else if (cmd.contains('настройки') || cmd.contains('settings') || cmd.contains('wifi') || cmd.contains('вайфай') || cmd.contains('вай-фай')) {
        if (cmd.contains('wifi') || cmd.contains('вайфай') || cmd.contains('вай-фай')) {
          await _open('android.settings.WIFI_SETTINGS');
        } else if (cmd.contains('bluetooth') || cmd.contains('блютуз')) {
          await _open('android.settings.BLUETOOTH_SETTINGS');
        } else {
          await _open('android.settings.SETTINGS');
        }
        result = 'Открываю настройки';
      }

      // ══ БУДИЛЬНИК ══
      else if (cmd.contains('будильник') || cmd.contains('alarm') || cmd.contains('разбуди')) {
        final time = RegExp(r'(\d{1,2})[:\.](\d{2})').firstMatch(cmd);
        if (time != null) {
          final h = int.parse(time.group(1)!);
          final m = int.parse(time.group(2)!);
          await _open('android.intent.action.SET_ALARM?android.intent.extra.alarm.HOUR=$h&android.intent.extra.alarm.MINUTES=$m');
          result = 'Ставлю будильник на ${time.group(0)}';
        } else {
          await _open('android.intent.action.SHOW_ALARMS');
          result = 'Открываю будильник';
        }
      }

      // ══ ТАЙМЕР ══
      else if (cmd.contains('таймер') || cmd.contains('timer')) {
        final mins = RegExp(r'(\d+)\s*(мин|минут|минуту)').firstMatch(cmd)?.group(1);
        final secs = RegExp(r'(\d+)\s*(сек|секунд)').firstMatch(cmd)?.group(1);
        if (mins != null) {
          await _open('android.intent.action.SET_TIMER?android.intent.extra.alarm.LENGTH=${int.parse(mins) * 60}');
          result = 'Ставлю таймер на $mins минут';
        } else if (secs != null) {
          await _open('android.intent.action.SET_TIMER?android.intent.extra.alarm.LENGTH=$secs');
          result = 'Ставлю таймер на $secs секунд';
        } else {
          await _open('android.intent.action.SHOW_TIMERS');
          result = 'Открываю таймер';
        }
      }

      // ══ КАЛЬКУЛЯТОР ══
      else if (cmd.contains('калькулятор') || cmd.contains('calculator')) {
        bool ok = await _open('android-app://com.google.android.calculator');
        if (!ok) await _open('android-app://com.android.calculator2');
        result = 'Открываю калькулятор';
      }

      // ══ ПОИСК В ИНТЕРНЕТЕ ══
      else if (cmd.contains('найди') || cmd.contains('поищи') || cmd.contains('загугли') || cmd.contains('погода')) {
        final query = _extract(cmd, ['найди', 'поищи', 'загугли']);
        final enc = Uri.encodeComponent(query.isEmpty ? cmd : query);
        await _open('https://www.google.com/search?q=$enc');
        result = 'Ищу: ${query.isEmpty ? cmd : query}';
      }

      // ══ NETFLIX ══
      else if (cmd.contains('netflix') || cmd.contains('нетфликс')) {
        final query = _extract(cmd, ['netflix', 'нетфликс']);
        if (query.isNotEmpty) {
          await _open('nflx://www.netflix.com/search?q=${Uri.encodeComponent(query)}');
        } else {
          bool ok = await _open('nflx://www.netflix.com/');
          if (!ok) await _open('https://netflix.com');
        }
        result = 'Открываю Netflix';
      }

      // ══ DISCORD ══
      else if (cmd.contains('discord') || cmd.contains('дискорд')) {
        await _open('discord://');
        result = 'Открываю Discord';
      }

      // ══ ZOOM ══
      else if (cmd.contains('zoom') || cmd.contains('зум')) {
        await _open('zoomus://zoom.us/join');
        result = 'Открываю Zoom';
      }

      // ══ SMS ══
      else if (cmd.contains('смс') || cmd.contains('сообщение') && !cmd.contains('telegram') && !cmd.contains('whatsapp')) {
        final text = _extract(cmd, ['смс', 'сообщение', 'напиши', 'отправь']);
        if (text.isNotEmpty) {
          await _open('sms:?body=${Uri.encodeComponent(text)}');
        } else {
          await _open('sms:');
        }
        result = 'Открываю сообщения';
      }

      // ══ PLAY MARKET ══
      else if (cmd.contains('play market') || cmd.contains('плей маркет') || cmd.contains('магазин приложений')) {
        final query = _extract(cmd, ['play market', 'плей маркет', 'магазин приложений', 'скачай', 'установи']);
        if (query.isNotEmpty) {
          await _open('market://search?q=${Uri.encodeComponent(query)}');
        } else {
          await _open('market://');
        }
        result = 'Открываю Play Market';
      }

      // ══ БРАУЗЕР / САЙТ ══
      else if (cmd.contains('открой сайт') || cmd.contains('зайди на') || cmd.contains('http') || cmd.contains('.com') || cmd.contains('.ru')) {
        String url = cmd
            .replaceAll(RegExp(r'открой сайт|зайди на|открой'), '')
            .trim();
        if (!url.startsWith('http')) url = 'https://$url';
        await _open(url);
        result = 'Открываю $url';
      }

      // ══ НЕИЗВЕСТНАЯ КОМАНДА — ищем в Play Market ══
      else {
        HapticFeedback.mediumImpact();
        result = 'Команда получена';
      }

    } catch (e) {
      result = 'Не удалось выполнить';
    }

    HapticFeedback.lightImpact();
    final safe = result.replaceAll("'", "\\'");
    _controller.runJavaScript(
      "if(window.onFlutterResponse) window.onFlutterResponse('$safe')",
    );
  }

  Future<bool> _open(String url) async {
    try {
      return await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
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
                          color: Color(0xFFF0C040),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
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
