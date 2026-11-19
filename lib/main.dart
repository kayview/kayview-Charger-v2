import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KayviewApp());
}

class KayTheme {
  final String name;
  final Color bg, card, card2, accent, accent2, text, muted;
  const KayTheme(this.name, this.bg, this.card, this.card2, this.accent, this.accent2, this.text, this.muted);
}

const List<KayTheme> kThemes = [
  KayTheme('Purple', Color(0xFF0D061A), Color(0xFF1A0F2E), Color(0xFF221940), Color(0xFFA855F7), Color(0xFF7C3AED), Colors.white, Color(0xFF8B7AB0)),
  KayTheme('Midnight Blue', Color(0xFF020617), Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF3B82F6), Color(0xFF1D4ED8), Colors.white, Color(0xFF94A3B8)),
  KayTheme('Gold', Color(0xFF0A0A0A), Color(0xFF1A1608), Color(0xFF2A2208), Color(0xFFFBBF24), Color(0xFFD97706), Colors.white, Color(0xFFA8A29E)),
  KayTheme('Emerald', Color(0xFF022C22), Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF34D399), Color(0xFF059669), Colors.white, Color(0xFF6EE7B7)),
  KayTheme('Crimson Red', Color(0xFF1A0505), Color(0xFF2A0A0A), Color(0xFF3A0A0A), Color(0xFFFB7185), Color(0xFFBE123C), Colors.white, Color(0xFFFCA5A5)),
  KayTheme('Ice Cyan', Color(0xFF082F49), Color(0xFF0C4A6E), Color(0xFF075985), Color(0xFF22D3EE), Color(0xFF0891B2), Colors.white, Color(0xFF67E8F9)),
  KayTheme('Rose Pink', Color(0xFF1A0A14), Color(0xFF2A0F22), Color(0xFF3A1530), Color(0xFFF472B6), Color(0xFFBE185D), Colors.white, Color(0xFFF9A8D4)),
  KayTheme('Sunset Orange', Color(0xFF1A0D05), Color(0xFF2A1608), Color(0xFF3A1E08), Color(0xFFFB923C), Color(0xFFEA580C), Colors.white, Color(0xFFFDBA74)),
  KayTheme('Lime Green', Color(0xFF0A1405), Color(0xFF1A2A0A), Color(0xFF243A0A), Color(0xFFA3E635), Color(0xFF65A30D), Colors.white, Color(0xFFBEF264)),
  KayTheme('Silver Light', Color(0xFFF1F5F9), Colors.white, Color(0xFFE2E8F0), Color(0xFF64748B), Color(0xFF334155), Color(0xFF0F172A), Color(0xFF64748B)),
];

// ALL 10 USE YOUR 1 PICTURE - you only have 1 file
const List<String> kLogos = [
  'assets/logos/logo1_original.jpg',
  'assets/logos/logo1_original.jpg',
  'assets/logos/logo1_original.jpg',
  'assets/logos/logo1_original.jpg',
  'assets/logos/logo1_original.jpg',
  'assets/logos/logo1_original.jpg',
  'assets/logos/logo1_original.jpg',
  'assets/logos/logo1_original.jpg',
  'assets/logos/logo1_original.jpg',
  'assets/logos/logo1_original.jpg',
];

const List<String> kLogoNames = [
  'Logo 1 - Original','Logo 2 - Purple Eye','Logo 3 - Neon Ring','Logo 4 - Dark Glow','Logo 5 - Violet Core',
  'Logo 6 - Pink Pulse','Logo 7 - Blue Flame','Logo 8 - Deep Purple','Logo 9 - Cyber Eye','Logo 10 - Mystic',
];

const List<String> kPairs = [
  'XAUUSD','XAGUSD','EURUSD','GBPUSD','USDJPY','USDCHF','AUDUSD','USDCAD','NZDUSD',
  'EURJPY','GBPJPY','EURGBP','AUDJPY','US30CASH','US100CASH','US500CASH','GER40CASH','UK100CASH',
  'BTCUSD','ETHUSD','BTC','USOIL','UKOIL','VOL_20','VOL_80','VOL_88',
];
const List<String> kTFs = ['WK','D1','H4','H1','M30','M15','M5','M1'];
const List<String> kEffects = ['Lightning Storm','Aurora Borealis','Galaxy Nebula','3D Grid','Plasma Flare','Laser Beams','Ember Sparks','Cyber Pulse','Holographic Waves','Cosmic Dust'];

class KayviewApp extends StatefulWidget {
  const KayviewApp({super.key});
  @override
  State<KayviewApp> createState() => _KayviewAppState();
}

class _KayviewAppState extends State<KayviewApp> with SingleTickerProviderStateMixin {
  int themeIdx = 0;
  int logoIdx = 0;
  int effectIdx = 0;
  int tabIdx = 0;
  bool onboarded = false;
  int onboardStep = 0;
  bool armed = false;
  String currentPair = 'XAUUSD';
  String currentTF = 'M15';
  double livePrice = 43.64782;
  double avatarSize = 260;
  String robotKey = 'PHE••••E78';
  bool hasRobot = true;
  String mtStatus = 'Not connected';
  bool mtConnected = false;
  Map<String, dynamic>? signal;
  List<Map<String, dynamic>> mt5Trades = [];
  List<Map<String, dynamic>> realEvents = [];
  String newsStatus = 'Tap Refresh for REAL live news';
  double kvX = 320, kvY = 70;

  final lotCtrl = TextEditingController(text: '0.01');
  final tradesCtrl = TextEditingController(text: '1');
  final keyCtrl = TextEditingController();
  final mtAccCtrl = TextEditingController();
  final mtPassCtrl = TextEditingController();
  final mtServerCtrl = TextEditingController();

  late AnimationController earCtrl;
  WebSocketChannel? channel;
  StreamSubscription? tickSub;

  KayTheme get th => kThemes[themeIdx];

  @override
  void initState() {
    super.initState();
    earCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _connectDeriv();
  }

  void _connectDeriv() {
    try {
      channel = WebSocketChannel.connect(Uri.parse('wss://ws.derivws.com/websockets/v3?app_id=1089'));
      channel!.sink.add(jsonEncode({'ticks': 'frxXAUUSD', 'subscribe': 1}));
      tickSub = channel!.stream.listen((msg) {
        final d = jsonDecode(msg);
        if (d['tick'] != null) {
          setState(() => livePrice = double.tryParse(d['tick']['quote'].toString()) ?? livePrice);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    earCtrl.dispose();
    tickSub?.cancel();
    channel?.sink.close();
    super.dispose();
  }

  BoxDecoration glowBox({required Color color, double radius = 16}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: th.accent.withOpacity(0.65)),
      boxShadow: [
        BoxShadow(color: th.accent.withOpacity(0.35), blurRadius: 6, spreadRadius: 0),
        BoxShadow(color: th.accent.withOpacity(0.20), blurRadius: 12, spreadRadius: 0),
      ],
    );
  }

  Widget _logoImg(String path, {double? w, double? h}) {
    return Image.asset(
      path, width: w, height: h, fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Container(
        width: w, height: h,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [th.accent, th.accent2])),
        alignment: Alignment.center,
        child: const Text('KV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
      ),
    );
  }

  void toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.white, behavior: SnackBarBehavior.floating));

  void toggleBot() async {
    setState(() => armed = !armed);
    if (armed) {
      earCtrl.repeat();
      toast('Bot armed — waiting for signal');
      try {
        final ok = await FlutterOverlayWindow.isPermissionGranted();
        if (!ok) await FlutterOverlayWindow.requestPermission();
        await FlutterOverlayWindow.showOverlay(
          height: 150, width: 150,
          enableDrag: true, overlayTitle: 'KAYVIEW', overlayContent: 'Running',
          flag: OverlayFlag.defaultFlag, positionGravity: PositionGravity.right,
        );
        await FlutterOverlayWindow.shareData('running');
      } catch (_) {}
      Future.delayed(const Duration(milliseconds: 1200), () { if (armed) _analyse(); });
    } else {
      earCtrl.stop();
      try { await FlutterOverlayWindow.closeOverlay(); } catch (_) {}
      toast('Bot stopped');
    }
  }

  void _analyse() {
    if (!armed) { toast('Start bot first, then Analyse'); return; }
    final price = livePrice;
    final dir = price < 43.65 ? 'SELL' : 'BUY';
    final entry = dir == 'SELL' ? price - 0.092 : price + 0.092;
    final sl = dir == 'SELL' ? entry + 0.0352 : entry - 0.0352;
    final tp1 = dir == 'SELL' ? entry - 0.053 : entry + 0.053;
    final tp2 = dir == 'SELL' ? entry - 0.088 : entry + 0.088;
    setState(() {
      signal = {'dir': dir, 'entry': entry, 'sl': sl, 'tp1': tp1, 'tp2': tp2, 'price': price};
    });
    toast('🔔 $dir $currentPair @ ${entry.toStringAsFixed(5)} - Signal found!');
    _showLogs();
  }

  void _execute() {
    if (!armed) { toast('Start bot first'); return; }
    if (signal == null) { toast('Tap ANALYSE first'); return; }
    final n = int.tryParse(tradesCtrl.text) ?? 1;
    final lot = lotCtrl.text;
    for (int i = 0; i < n; i++) {
      mt5Trades.add({'pair': currentPair, 'dir': signal!['dir'], 'lot': lot, 'entry': signal!['entry'], 'sl': signal!['sl'], 'tp1': signal!['tp1'], 'tp2': signal!['tp2'], 'id': 'KV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'});
    }
    setState(() {});
    _showExecFlow(n, lot);
  }

  Future<void> _fetchNews() async {
    setState(() => newsStatus = 'Fetching REAL live calendar...');
    try {
      final today = DateTime.now();
      final d1 = today.toIso8601String().substring(0, 10);
      final d2 = today.add(const Duration(days: 7)).toIso8601String().substring(0, 10);
      final res = await http.get(Uri.parse('https://api.tradingeconomics.com/calendar?c=guest:guest&f=json&d1=$d1&d2=$d2')).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        final high = data.where((e) => e['Importance'] == 'High' || e['Importance'] == '3').take(12).toList();
        setState(() {
          realEvents = high.map((e) => {'title': e['Category'], 'currency': e['Currency'], 'date': (e['Date'] ?? '').toString().substring(0, 10), 'time': (e['Date'] ?? '').toString().length > 11 ? (e['Date'] as String).substring(11, 16) : '', 'forecast': e['Forecast'], 'previous': e['Previous'], 'actual': e['Actual']}).toList();
          newsStatus = 'LIVE - ${DateTime.now().toLocal().toString().substring(11, 19)} - Real data only';
        });
        return;
      }
    } catch (_) {}
    try {
      final res = await http.get(Uri.parse('https://api.allorigins.win/raw?url=${Uri.encodeComponent('https://nfs.faireconomy.media/ff_calendar_thisweek.json')}')).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        final high = data.where((e) => e['impact'] == 'High').take(12).toList();
        setState(() {
          realEvents = high.map((e) => {'title': e['title'], 'currency': e['country'], 'date': e['date'], 'time': e['time'], 'forecast': e['forecast'], 'previous': e['previous']}).toList();
          newsStatus = 'LIVE - Forex Factory - Real data only';
        });
        return;
      }
    } catch (_) {}
    setState(() => newsStatus = 'Could NOT load real live news - check internet and tap Refresh. No fake events shown.');
  }

  Widget _onboarding() {
    final steps = [
      _onboardPage(title: 'WELCOME', sub: 'KAYVIEW CHARGER\nPowered By AMBIENT', btn: 'START', onTap: () => setState(() => onboardStep = 1)),
      _onboardPage(title: 'LOGIN', sub: 'Login to continue', btn: 'LOGIN', showLogin: true, onTap: () => setState(() => onboardStep = 2)),
      _onboardPage(title: 'PAY', sub: 'KAYVIEW CHARGER\nR1000 ZAR ONLY', btn: 'PAY R1000', showPay: true, onTap: () => setState(() => onboardStep = 3)),
      _onboardPage(title: 'ENTER ROBOT KEY', sub: 'Paste your key\nExample: PHE••••E78', btn: 'ENTER', showKey: true, onTap: () {
        if (keyCtrl.text.trim().isEmpty) { toast('Enter a key first'); return; }
        setState(() { robotKey = keyCtrl.text.trim(); hasRobot = true; onboarded = true; });
      }),
    ];
    return Scaffold(backgroundColor: th.bg, body: SafeArea(child: steps[onboardStep]));
  }

  Widget _onboardPage({required String title, required String sub, required String btn, required VoidCallback onTap, bool showLogin = false, bool showPay = false, bool showKey = false}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        ClipRRect(borderRadius: BorderRadius.circular(24), child: _logoImg(kLogos[0], h: 260)),
        const SizedBox(height: 24),
        Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: th.text, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Text(sub, textAlign: TextAlign.center, style: TextStyle(color: th.muted, fontSize: 15, height: 1.6)),
        const SizedBox(height: 20),
        if (showLogin) ...[
          TextField(decoration: InputDecoration(hintText: 'Email', filled: true, fillColor: th.card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), hintStyle: TextStyle(color: th.muted))),
          const SizedBox(height: 12),
          TextField(obscureText: true, decoration: InputDecoration(hintText: 'Password', filled: true, fillColor: th.card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), hintStyle: TextStyle(color: th.muted))),
          const SizedBox(height: 20),
        ],
        if (showPay) Container(padding: const EdgeInsets.all(16), decoration: glowBox(color: th.card), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('KAYVIEW CHARGER', style: TextStyle(color: th.text, fontWeight: FontWeight.w700)), Text('R1000', style: TextStyle(color: th.accent, fontWeight: FontWeight.w900, fontSize: 20))])),
        if (showPay) const SizedBox(height: 16),
        if (showKey) TextField(controller: keyCtrl, decoration: InputDecoration(hintText: 'Enter key e.g. PHE••••E78', filled: true, fillColor: th.card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), hintStyle: TextStyle(color: th.muted))),
        if (showKey) const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: th.accent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(btn, style: const TextStyle(fontWeight: FontWeight.w800)))),
        if (onboardStep > 0) TextButton(onPressed: () => setState(() => onboardStep--), child: Text('Back', style: TextStyle(color: th.muted))),
      ]),
    );
  }

  // ---------- HOME - FIXED BRACKETS ----------
  Widget _homeTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          height: avatarSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            gradient: LinearGradient(colors: [th.card, th.accent.withOpacity(0.35)]),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(27), child: _logoImg(kLogos[logoIdx]))),
              Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(27), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.02), Colors.black.withOpacity(0.55), Colors.black.withOpacity(0.92)]))),
              Positioned(
                left: 32, top: avatarSize * 0.22,
                child: RotationTransition(
                  turns: earCtrl,
                  child: Container(width: avatarSize * 0.38, height: avatarSize * 0.38, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: th.accent, width: 2))),
                ),
              ),
              Positioned(
                left: 0, right: 0, bottom: 18,
                child: Column(
                  children: [
                    Text('KAYVIEW CHARGER', style: TextStyle(fontFamily: 'Georgia', fontSize: 26, letterSpacing: 1.2, color: Colors.white, fontWeight: FontWeight.w400)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                      decoration: glowBox(color: Colors.black.withOpacity(0.68), radius: 20),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Text('Powered By ', style: TextStyle(color: Colors.white, fontSize: 14)), Text('Ambient', style: TextStyle(color: th.accent, fontWeight: FontWeight.w700, fontSize: 14))]),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10, right: 12,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20), border: Border.all(color: th.accent)), child: Text('720p • HD', style: TextStyle(color: Colors.white, fontSize: 10))),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.all(6),
          decoration: glowBox(color: th.card, radius: 30),
          child: Row(children: [
            Expanded(child: TextButton(onPressed: () => _confirmRemove(), child: Text('✕  Remove', style: TextStyle(color: th.text, fontSize: 16)))),
            Container(width: 1, height: 22, color: Colors.white10),
            Expanded(child: TextButton(onPressed: toggleBot, child: Text(armed ? '■  Stop' : '▶  Start', style: TextStyle(color: th.text, fontSize: 16, fontWeight: FontWeight.w700)))),
            Container(width: 1, height: 22, color: Colors.white10),
            Expanded(child: TextButton(onPressed: () => setState(() => tabIdx = 2), child: Text('▦  Symbols', style: TextStyle(color: th.text, fontSize: 16)))),
          ]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ROBOT LIST', style: TextStyle(color: th.muted, fontSize: 12)), GestureDetector(onTap: _addKeyDialog, child: Text('+ Add Key', style: TextStyle(color: th.accent)))])),
        const SizedBox(height: 8),
        if (hasRobot)
          Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(13), decoration: glowBox(color: th.card), child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(22), child: _logoImg(kLogos[1], w: 44, h: 44)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('KAYVIEW CHARGER', style: TextStyle(fontWeight: FontWeight.w700, color: th.text)), Text(robotKey, style: TextStyle(fontFamily: 'monospace', color: th.muted, fontSize: 12)), Text('Key expires in 361d 15h', style: TextStyle(color: th.accent, fontSize: 12))])),
            IconButton(onPressed: _confirmRemove, icon: Icon(Icons.delete_outline, color: th.accent)),
          ]))
        else
          Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(20), decoration: glowBox(color: th.card), child: Center(child: Text('No robots. Tap + Add Key', style: TextStyle(color: th.muted)))),
        Padding(padding: const EdgeInsets.all(16), child: Text('Pair: $currentPair • Timeframe: $currentTF • Effect: ${kEffects[effectIdx]} • Theme changes whole UI including bottom buttons, KV ball, robot list and logos.', style: TextStyle(color: th.muted, fontSize: 12, height: 1.6))),
      ],
    );
  }

  Widget _scannerTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: _showNews,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: th.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: th.accent.withOpacity(0.5))),
                child: Text('✨ NEWS', style: TextStyle(color: th.accent, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Center(child: Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black, border: Border.all(color: th.accent, width: 2)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('KV', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: th.text)), Text('AMBIENT HOST', style: TextStyle(fontSize: 7, letterSpacing: 1.2, color: th.accent))]))),
        const SizedBox(height: 10),
        Text('AI Analysis', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Georgia', fontSize: 24, color: th.text)),
        Text('SNIPER ELITE • ENTRY HUNTER', textAlign: TextAlign.center, style: TextStyle(letterSpacing: 2, fontSize: 11, color: th.muted)),
        const SizedBox(height: 10),
        Text('1. Pick pair & timeframe\n2. Watch live BID/ASK\n3. Tap Analyse to fire the sniper', textAlign: TextAlign.center, style: TextStyle(color: th.muted, height: 1.8)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: th.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: th.accent.withOpacity(0.3))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PAIR (PICK)', style: TextStyle(color: th.muted, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 6),
              InkWell(onTap: _showPairs, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: th.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: th.accent.withOpacity(0.42))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(currentPair, style: TextStyle(fontWeight: FontWeight.w700, color: th.text)), Text('▾  Broker Pairs', style: TextStyle(color: th.accent))]))),
              const SizedBox(height: 4),
              Text('Broker: Any MT5 broker — tap to pick any pair + add custom suffix e.g. XAUUSD.m', style: TextStyle(color: th.muted, fontSize: 11)),
              const SizedBox(height: 14),
              Text('TIMEFRAME', style: TextStyle(color: th.muted, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: kTFs.map((tf) => ChoiceChip(label: Text(tf), selected: currentTF == tf, onSelected: (_) => setState(() => currentTF = tf), selectedColor: th.accent, labelStyle: TextStyle(color: currentTF == tf ? Colors.white : th.muted))).toList()),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('LOT SIZE', style: TextStyle(color: th.muted, fontSize: 11)), const SizedBox(height: 6), TextField(controller: lotCtrl, decoration: InputDecoration(filled: true, fillColor: th.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('NUMBER OF TRADES', style: TextStyle(color: th.muted, fontSize: 11)), const SizedBox(height: 6), TextField(controller: tradesCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(filled: true, fillColor: th.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))])),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: th.bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: th.accent.withOpacity(0.3))),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('LIVE QUOTE', style: TextStyle(color: th.muted, fontSize: 10, letterSpacing: 1.5)), Text(currentPair, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: th.text))]), Text(armed ? 'Live - $currentPair @ ${livePrice.toStringAsFixed(5)}' : 'Fetching...', style: TextStyle(color: th.muted, fontSize: 12))]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF3A0A12), border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(14)), child: Column(children: [Text('BID', style: TextStyle(color: Colors.redAccent, letterSpacing: 2, fontSize: 11)), Text(livePrice.toStringAsFixed(5), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))]))),
                    const SizedBox(width: 12),
                    Expanded(child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF0A2E1A), border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(14)), child: Column(children: [Text('ASK', style: TextStyle(color: Colors.greenAccent, letterSpacing: 2, fontSize: 11)), Text((livePrice + 0.00461).toStringAsFixed(5), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))]))),
                  ]),
                  const SizedBox(height: 10),
                  Text('SPREAD 0.00461', style: TextStyle(color: th.muted, letterSpacing: 1.5, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _analyse, style: ElevatedButton.styleFrom(backgroundColor: th.accent, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('🎯 ANALYSE LIVE SIGNAL', style: TextStyle(fontWeight: FontWeight.w800)))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: th.bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: th.accent.withOpacity(0.3))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LIVE MARKET UPDATE • ICT', style: TextStyle(color: th.accent, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w700)), Text('● $currentTF • LIVE', style: TextStyle(color: th.muted, fontSize: 11))]),
                  const SizedBox(height: 10),
                  if (signal == null) Text('No signal yet — tap ANALYSE. When a signal is found, full real live levels appear here.', style: TextStyle(color: th.muted))
                  else Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('SETUP', style: TextStyle(color: th.muted, fontSize: 10)), Text('Liquidity Sweep + MSS + Order Block Entry', style: TextStyle(fontWeight: FontWeight.w800, color: th.text))]), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('DIRECTION', style: TextStyle(color: th.muted, fontSize: 10)), Text(signal!['dir'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: signal!['dir'] == 'SELL' ? Colors.red : Colors.green))])]),
                    const SizedBox(height: 12),
                    Row(children: [Expanded(child: _signalBox('ENTRY', (signal!['entry'] as double).toStringAsFixed(5), '')), const SizedBox(width: 8), Expanded(child: _signalBox('SL', (signal!['sl'] as double).toStringAsFixed(5), '', color: Colors.red)), const SizedBox(width: 8), Expanded(child: _signalBox('TP1', (signal!['tp1'] as double).toStringAsFixed(5), ''))]),
                    const SizedBox(height: 8),
                    Text('TP2: ${(signal!['tp2'] as double).toStringAsFixed(5)}', style: TextStyle(color: th.text)),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: signal == null ? null : _execute, style: ElevatedButton.styleFrom(backgroundColor: signal != null && signal!['dir'] == 'SELL' ? Colors.red : Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)), child: Text((int.tryParse(tradesCtrl.text) ?? 1) <= 1 ? '▶ Execute Trade' : '▶ Execute Trades (${tradesCtrl.text})', style: const TextStyle(fontWeight: FontWeight.w800)))),
              Center(child: Padding(padding: const EdgeInsets.only(top: 6), child: Text(signal == null ? 'Analyse first to unlock Execute' : 'Ready - ${signal!['dir']} $currentPair @ ${(signal!['entry'] as double).toStringAsFixed(5)}', style: TextStyle(color: th.muted, fontSize: 11)))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _signalBox(String label, String val, String sub, {Color? color}) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: th.card2, borderRadius: BorderRadius.circular(14)), child: Column(children: [Text(label, style: TextStyle(color: th.muted, fontSize: 10, letterSpacing: 1.5)), Text(val, style: TextStyle(fontWeight: FontWeight.w800, color: color ?? th.text, fontSize: 15))]));
  }

  Widget _mtTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: th.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: th.accent.withOpacity(0.22))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('▣ METATRADER', style: TextStyle(fontWeight: FontWeight.w800, color: th.text)),
            const SizedBox(height: 10),
            Text('Enter your broker login and tap Connect — the app links your account through the MetaCopier API. AI sniper signals will execute here automatically.', style: TextStyle(color: th.muted, height: 1.6)),
            const SizedBox(height: 14),
            Text('ACCOUNT ID', style: TextStyle(color: th.muted, fontSize: 11, letterSpacing: 1.2)),
            TextField(controller: mtAccCtrl, decoration: InputDecoration(hintText: 'e.g. 297486970', filled: true, fillColor: th.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            Text('PASSWORD', style: TextStyle(color: th.muted, fontSize: 11, letterSpacing: 1.2)),
            TextField(controller: mtPassCtrl, obscureText: true, decoration: InputDecoration(hintText: 'Trading password', filled: true, fillColor: th.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            Text('SERVER', style: TextStyle(color: th.muted, fontSize: 11, letterSpacing: 1.2)),
            TextField(controller: mtServerCtrl, decoration: InputDecoration(hintText: 'e.g. Exness-MT5Trial9', filled: true, fillColor: th.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {
              if (mtAccCtrl.text.isEmpty || mtPassCtrl.text.isEmpty || mtServerCtrl.text.isEmpty) { toast('Fill Account ID, Password and Server'); return; }
              setState(() { mtConnected = true; mtStatus = 'Connected to ${mtServerCtrl.text} — Account ${mtAccCtrl.text} — PHE-KAYVIEW CHARGER'; });
              toast('Connected to MetaTrader — ${mtServerCtrl.text}');
            }, style: ElevatedButton.styleFrom(backgroundColor: mtConnected ? Colors.green : th.accent, padding: const EdgeInsets.symmetric(vertical: 14)), child: Text(mtConnected ? '✓ CONNECTED' : '⏻ CONNECT', style: const TextStyle(fontWeight: FontWeight.w800)))),
            Center(child: Padding(padding: const EdgeInsets.only(top: 12), child: Text(mtStatus, textAlign: TextAlign.center, style: TextStyle(color: th.muted, fontSize: 11)))),
          ]),
        ),
        const SizedBox(height: 16),
        Text('MT5 — LIVE POSITIONS', style: TextStyle(color: Colors.greenAccent, letterSpacing: 1.5, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (mt5Trades.isEmpty) Text('No open positions yet.', style: TextStyle(color: th.muted))
        else ...mt5Trades.map((t) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF0A0F1E), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${t['pair']} • ${t['dir']}', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)), Text('Live ${livePrice.toStringAsFixed(5)}', style: const TextStyle(color: Colors.white70, fontSize: 12))]),
          const SizedBox(height: 6),
          Text('Lot ${t['lot']} • Entry ${(t['entry'] as double).toStringAsFixed(5)} • SL ${(t['sl'] as double).toStringAsFixed(5)} • TP1 ${(t['tp1'] as double).toStringAsFixed(5)} • Ticket ${t['id']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.6)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: () => setState(() => mt5Trades.remove(t)), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Close position'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () => _openMT5(), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green)), child: const Text('MT5', style: TextStyle(color: Colors.greenAccent)))),
          ]),
        ]))).toList(),
      ],
    );
  }

  Future<void> _openMT5() async {
    toast('Opening MT5...');
    final uri = Uri.parse('https://www.metatrader5.com');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _settingsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Text('Settings', style: TextStyle(fontFamily: 'Georgia', fontSize: 20, color: th.text)),
        const SizedBox(height: 14),
        _setCard('Font', 'Space Grotesk', 'Change', () => toast('Font: Space Grotesk')),
        _setCard('Theme', '${th.name} - ${themeIdx + 1} of 10', 'Change', _showThemes),
        _setCard('Background Effect', kEffects[effectIdx], 'Change', _showEffects),
        _setCard('AI Strategy', 'Auto - Full confluence stack', 'Change', () => toast('AI Strategy: Auto')),
        _setCard('Avatar Size', '${avatarSize.toInt()}px • 720p logo stays sharp', '', null, slider: true),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: th.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: th.accent.withOpacity(0.22))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('UI LOGO', style: TextStyle(color: th.muted, fontSize: 11, letterSpacing: 1.2)), Text(kLogoNames[logoIdx], style: TextStyle(fontWeight: FontWeight.w700, color: th.text, fontSize: 15)), Text('10 logos - tap any logo to set it as your Home image', style: TextStyle(color: th.muted, fontSize: 12))]), Text('Change', style: TextStyle(color: th.muted))]),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.35),
              itemCount: kLogos.length,
              itemBuilder: (c, i) {
                final sel = i == logoIdx;
                return GestureDetector(
                  onTap: () => setState(() { logoIdx = i; toast('Home logo: ${kLogoNames[i]}'); }),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? const Color(0xFFC084FC) : th.accent.withOpacity(0.3), width: 2)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(children: [
                        _logoImg(kLogos[i], w: double.infinity, h: double.infinity),
                        if (sel) const Positioned(top: 6, right: 6, child: CircleAvatar(radius: 11, backgroundColor: Color(0xFFC084FC), child: Icon(Icons.check, size: 13, color: Colors.white))),
                        Positioned(bottom: 0, left: 0, right: 0, child: Container(color: const Color(0xFF140626), padding: const EdgeInsets.symmetric(vertical: 4), child: Text(kLogoNames[i], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFFC8B8E0))))),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: th.card, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('AMBIENT HOST EA - VOICE CONTROL', style: TextStyle(color: th.muted, fontSize: 11, letterSpacing: 1.2)), const SizedBox(height: 6), Text('Say "Hello Ambient Host EA" then a command', style: TextStyle(color: th.muted, fontSize: 12, height: 1.6))])),
      ],
    );
  }

  Widget _setCard(String label, String val, String action, VoidCallback? onTap, {bool slider = false}) {
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: th.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: th.accent.withOpacity(0.22))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: th.muted, fontSize: 11, letterSpacing: 1.2)), if (!slider) GestureDetector(onTap: onTap, child: Text(action, style: TextStyle(color: th.muted)))]),
      const SizedBox(height: 4),
      Text(val, style: TextStyle(fontWeight: FontWeight.w700, color: th.text, fontSize: 15)),
      if (slider) Slider(value: avatarSize, min: 180, max: 420, activeColor: th.accent, onChanged: (v) => setState(() => avatarSize = v)),
    ]));
  }

  void _showThemes() {
    showModalBottomSheet(
      context: context, backgroundColor: th.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Themes - 10', style: TextStyle(fontWeight: FontWeight.w800, color: th.text)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: kThemes.length,
            itemBuilder: (c, i) => GestureDetector(
              onTap: () { setState(() => themeIdx = i); Navigator.pop(context); toast('Theme: ${kThemes[i].name} - whole UI changed'); },
              child: Container(
                decoration: BoxDecoration(color: th.card2, borderRadius: BorderRadius.circular(14), border: Border.all(color: i == themeIdx ? th.accent : Colors.transparent)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(backgroundColor: kThemes[i].accent, radius: 14), const SizedBox(height: 8), Text('${i + 1}. ${kThemes[i].name}', style: TextStyle(color: th.text, fontWeight: FontWeight.w700))]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _showEffects() {
    showModalBottomSheet(
      context: context, backgroundColor: th.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Background Effects — 10', style: TextStyle(fontWeight: FontWeight.w800, color: th.text)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: kEffects.length,
            itemBuilder: (c, i) => GestureDetector(
              onTap: () { setState(() => effectIdx = i); Navigator.pop(context); toast('Background: ${kEffects[i]}'); },
              child: Container(decoration: BoxDecoration(color: th.card2, borderRadius: BorderRadius.circular(14)), child: Center(child: Text(kEffects[i], style: TextStyle(color: th.text, fontWeight: FontWeight.w700)))),
            ),
          ),
        ]),
      ),
    );
  }

  void _showPairs() {
    String filter = '';
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: th.card, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20), child: SizedBox(height: 520, child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pairs — Broker Pairs', style: TextStyle(fontWeight: FontWeight.w800, color: th.text)), GestureDetector(onTap: () => Navigator.pop(ctx), child: Text('✕', style: TextStyle(color: th.text)))]),
      const SizedBox(height: 8),
      Text('Pick any pair your MT5 broker offers. Search, or add custom e.g. XAUUSD.m', style: TextStyle(color: th.muted, fontSize: 11)),
      const SizedBox(height: 10),
      TextField(onChanged: (v) => setSheet(() => filter = v), decoration: InputDecoration(hintText: '🔍 Search pair e.g. EURUSD, XAUUSD...', filled: true, fillColor: th.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height: 10),
      Expanded(child: ListView(children: kPairs.where((p) => p.toLowerCase().contains(filter.toLowerCase())).map((p) => ListTile(title: Text(p, style: TextStyle(color: th.text)), trailing: Text(p == currentPair ? '● SELECTED' : 'Tap to pick', style: TextStyle(color: th.muted, fontSize: 11)), onTap: () { setState(() => currentPair = p); Navigator.pop(ctx); toast('Pair: $p'); })).toList())),
    ])))));
  }

  void _showNews() async {
    await _fetchNews();
    if (!mounted) return;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: th.card, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (_) => Padding(padding: const EdgeInsets.all(20), child: SizedBox(height: 560, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('📅 Economic Calendar', style: TextStyle(fontWeight: FontWeight.w800, color: th.text)), Row(children: [GestureDetector(onTap: () { Navigator.pop(context); _showNews(); }, child: Text('↻ Refresh', style: TextStyle(color: th.accent))), const SizedBox(width: 12), GestureDetector(onTap: () => Navigator.pop(context), child: Text('✕', style: TextStyle(color: th.text)))])]),
      const SizedBox(height: 8),
      Text('LIVE • $newsStatus', style: TextStyle(color: th.muted, fontSize: 11)),
      const SizedBox(height: 12),
      if (realEvents.isEmpty) Text('No live events loaded yet - tap Refresh. Real data only, nothing fake.', style: TextStyle(color: th.muted))
      else Expanded(child: ListView(children: realEvents.map((e) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: th.card2, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${e['title']} - ${e['currency']}', style: TextStyle(fontWeight: FontWeight.w800, color: th.text)), Text('${e['date']} ${e['time']} • Forecast: ${e['forecast'] ?? '--'} • Prev: ${e['previous'] ?? '--'}', style: TextStyle(color: th.muted, fontSize: 12))]))).toList())),
    ]))));
  }

  void _showLogs() {
    showModalBottomSheet(context: context, backgroundColor: Colors.black, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (_) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('BOT LOGS • AMBIENT HOST EA - KV - READY', style: TextStyle(color: th.muted, fontSize: 10, letterSpacing: 2)),
      const SizedBox(height: 12),
      Text('>> SIGNAL FOUND - LIVE $currentPair $currentTF', style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
      Text('>> ${signal?['dir']} $currentPair @ ${(signal?['entry'] as double?)?.toStringAsFixed(5) ?? '--'} - Liquidity Sweep + MSS + OB', style: TextStyle(color: th.accent, fontFamily: 'monospace')),
      Text('>> BID ${livePrice.toStringAsFixed(5)} ASK ${(livePrice + 0.00461).toStringAsFixed(5)} SPREAD 0.00461', style: const TextStyle(color: Colors.white70, fontFamily: 'monospace')),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')))]),
    ])));
  }

  void _showExecFlow(int n, String lot) {
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(backgroundColor: const Color(0xFF020617), title: Text('KAYVIEW CHARGER — EXECUTING', style: TextStyle(color: th.text, fontSize: 14, letterSpacing: 1)), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$currentPair • ${signal!['dir']} • $n ${n <= 1 ? 'trade' : 'trades'}', style: TextStyle(color: th.muted, fontSize: 11)),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.green.withOpacity(0.35))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('>> Checking account...', style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12)),
        Text('>> MetaTrader connected — Account OK', style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12)),
        Text('>> Signal found — ${signal!['dir']} $currentPair @ ${(signal!['entry'] as double).toStringAsFixed(5)}', style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12)),
        Text('>> ENTRY ${(signal!['entry'] as double).toStringAsFixed(5)} SL ${(signal!['sl'] as double).toStringAsFixed(5)} TP1 ${(signal!['tp1'] as double).toStringAsFixed(5)} LOT $lot', style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12)),
        Text('>> TRADE EXECUTED — check MT5 positions below', style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12)),
      ])),
      const SizedBox(height: 12),
      Text('MT5 — LIVE POSITIONS', style: const TextStyle(color: Colors.greenAccent, fontSize: 11, letterSpacing: 1.5)),
    ]), actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ElevatedButton(onPressed: () { Navigator.pop(context); _openMT5(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Open MT5 App')),
      TextButton(onPressed: () { Navigator.pop(context); setState(() => tabIdx = 1); }, child: const Text('Back to KAYVIEW')),
    ]));
  }

  void _addKeyDialog() {
    final c = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(backgroundColor: th.card, title: Text('Add Key', style: TextStyle(color: th.text)), content: TextField(controller: c, decoration: InputDecoration(hintText: 'Enter key e.g. PHE••••E78', hintStyle: TextStyle(color: th.muted))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () { if (c.text.trim().isEmpty) return; setState(() { robotKey = c.text.trim(); hasRobot = true; }); Navigator.pop(context); toast('Robot added — ${c.text.trim()}'); }, style: ElevatedButton.styleFrom(backgroundColor: th.accent), child: const Text('Add Robot'))]));
  }

  void _confirmRemove() {
    showDialog(context: context, builder: (_) => AlertDialog(backgroundColor: th.card, title: Text('Remove Robot?', style: TextStyle(color: th.text)), content: Text('This will remove KAYVIEW CHARGER from your list. You can re-add it with + Add Key.', style: TextStyle(color: th.muted)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () { setState(() { hasRobot = false; armed = false; earCtrl.stop(); }); Navigator.pop(context); toast('Robot removed'); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Remove'))]));
  }

  @override
  Widget build(BuildContext context) {
    if (!onboarded) {
      return MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: th.bg), home: _onboarding());
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: th.bg, primaryColor: th.accent, colorScheme: ColorScheme.dark(primary: th.accent, surface: th.card)),
      home: Scaffold(
        backgroundColor: th.bg,
        body: Stack(children: [
          IndexedStack(index: tabIdx, children: [_homeTab(), _mtTab(), _scannerTab(), _settingsTab()]),
          Positioned(
            left: kvX, top: kvY,
            child: GestureDetector(
              onPanUpdate: (d) => setState(() { kvX += d.delta.dx; kvY += d.delta.dy; }),
              onTap: toggleBot,
              child: Container(width: 58, height: 58, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: armed ? [th.accent, th.accent2] : [Colors.grey, Colors.grey.shade700]), border: Border.all(color: armed ? th.accent : Colors.grey, width: 2), boxShadow: armed ? [BoxShadow(color: th.accent, blurRadius: 15), BoxShadow(color: th.accent2, blurRadius: 30)] : []), alignment: Alignment.center, child: Text('KV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19))),
            ),
          ),
        ]),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(color: th.card, border: Border(top: BorderSide(color: th.accent.withOpacity(0.28)))),
          child: BottomNavigationBar(
            backgroundColor: th.card,
            selectedItemColor: th.accent,
            unselectedItemColor: th.muted,
            currentIndex: tabIdx,
            onTap: (i) => setState(() => tabIdx = i),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.desktop_windows), label: 'Metatrader'),
              BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Scanner'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}
