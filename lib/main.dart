import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void overlayMain() { runApp(const OverlayApp()); }

class OverlayApp extends StatefulWidget {
  const OverlayApp({super.key});
  @override
  State<OverlayApp> createState() => _OverlayAppState();
}

class _OverlayAppState extends State<OverlayApp> {
  bool isRunning = true;
  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is String) {
        if (data == 'STOP') setState(() => isRunning = false);
        if (data == 'START' || data == 'RUNNING') setState(() => isRunning = true);
      }
    });
  }
  void _toggle() {
    setState(() => isRunning = !isRunning);
    FlutterOverlayWindow.shareData(isRunning ? 'OVERLAY_RUNNING' : 'OVERLAY_STOPPED');
    HapticFeedback.mediumImpact();
  }
  @override
  Widget build(BuildContext context) {
    final glow = isRunning ? const Color(0xFFFF2E88) : const Color(0xFF9CA3AF);
    final bg = isRunning ? const Color(0xFF1A0A1E) : const Color(0xFF1F2937);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: _toggle,
          onPanUpdate: (d) => FlutterOverlayWindow.moveOverlay(OverlayPosition(d.globalPosition.dx, d.globalPosition.dy)),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: glow, width: 2.5),
              boxShadow: [BoxShadow(color: glow.withOpacity(0.6), blurRadius: 22, spreadRadius: 4)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('KV', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                Icon(isRunning ? Icons.pause : Icons.play_arrow, color: glow, size: 16),
                Text(isRunning ? 'RUNNING' : 'STOPPED', style: TextStyle(color: glow, fontSize: 7, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() => runApp(const KayviewApp());

class KayviewApp extends StatelessWidget {
  const KayviewApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, home: KayviewRoot());
  }
}

enum OnboardStep { splash, start, login, pay, tradeSolutions, robotKey, home }

class KayviewRoot extends StatefulWidget {
  const KayviewRoot({super.key});
  @override
  State<KayviewRoot> createState() => _KayviewRootState();
}

class _KayviewRootState extends State<KayviewRoot> {
  OnboardStep step = OnboardStep.splash;
  final emailCtrl = TextEditingController();
  final keyCtrl = TextEditingController();
  bool checking = false;
  bool activating = false;
  bool agreed = false;
  String? email;
  String? robotKey;

  @override
  void initState() {
    super.initState();
    _loadSaved();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && step == OnboardStep.splash) setState(() => step = OnboardStep.start);
    });
  }

  Future<void> _loadSaved() async {
    final p = await SharedPreferences.getInstance();
    if ((p.getBool('kayview_onboarded') ?? false) && mounted) setState(() => step = OnboardStep.home);
  }

  Future<void> _finish() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('kayview_onboarded', true);
    await p.setString('kayview_email', email ?? '');
    await p.setString('kayview_robot_key', robotKey ?? '');
    setState(() => step = OnboardStep.home);
  }

  Widget _logo({double s = 72}) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white24)),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('KV', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          Text('KAYVIEW', style: TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 3)),
          Text('CHARGER', style: TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 3)),
        ],
      ),
    );
  }

  Widget _scaffold(Widget c) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1E),
      body: SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: c)),
    );
  }

  Widget _btn(String l, VoidCallback? f, {bool loading = false, Color color = const Color(0xFF6D28D9), Color txt = Colors.white}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: f,
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(l, style: TextStyle(color: txt, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildSplash() {
    return _scaffold(
      Column(
        children: [
          const Spacer(),
          _logo(s: 110),
          const SizedBox(height: 28),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('WELCOME TO ', style: TextStyle(color: Colors.white, fontSize: 20)),
              Text('KAYVIEW', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('CHARGER  •  HOW TO GUIDE', style: TextStyle(color: Colors.white70, letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text('POWERED BY AMBIENT', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 3)),
          const Spacer(),
          const Text('AMBIENT HOST EA - KV - READY', style: TextStyle(color: Colors.white30, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildStart() {
    return _scaffold(
      Column(
        children: [
          const Spacer(),
          _logo(s: 90),
          const SizedBox(height: 24),
          const Text('KAYVIEW CHARGER', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('POWERED BY AMBIENT', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
          const Spacer(),
          _btn('START', () => setState(() => step = OnboardStep.login)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLogin() {
    return _scaffold(
      Column(
        children: [
          Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: () => setState(() => step = OnboardStep.start), icon: const Icon(Icons.arrow_back, color: Colors.white))),
          const Spacer(),
          _logo(),
          const SizedBox(height: 20),
          const Text('LOGIN', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 20),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(hintText: 'EMAIL', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: const Color(0xFF1F2937), border: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
          ),
          const SizedBox(height: 16),
          _btn(checking ? 'CHECKING...' : 'PROCEED', checking ? null : () {
            if (emailCtrl.text.trim().isEmpty || !emailCtrl.text.contains('@')) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email')));
              return;
            }
            setState(() => checking = true);
            email = emailCtrl.text.trim();
            Future.delayed(const Duration(milliseconds: 800), () {
              if (!mounted) return;
              setState(() { checking = false; step = OnboardStep.pay; });
            });
          }, loading: checking),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPay() {
    return _scaffold(
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(onPressed: () => setState(() => step = OnboardStep.login), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                const Text('Pay for App', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: () => setState(() => step = OnboardStep.home), icon: const Icon(Icons.close, color: Colors.white54)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('KAYVIEW CHARGER', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Get instant access to professional trading tool and expert advisor.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  const Text('R1000', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  const Text('One-time purchase • ZAR', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 12),
                  const Text('✓ Professional Trading Tool\n✓ Expert Advisor (EA)\n✓ Instant Access\n✓ 24/7 Support', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(value: agreed, activeColor: const Color(0xFF6D28D9), onChanged: (v) => setState(() => agreed = v ?? false)),
                      const Expanded(child: Text('I agree to Privacy Policy, Terms of Service and Refund Policy', style: TextStyle(color: Colors.white70, fontSize: 12))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _btn('Buy Now', !agreed ? null : () => setState(() => step = OnboardStep.tradeSolutions), color: const Color(0xFFFACC15), txt: Colors.black),
            const SizedBox(height: 12),
            const Center(child: Text('Copyright © 2026 KAYVIEW CHARGER', style: TextStyle(color: Colors.white30, fontSize: 10))),
          ],
        ),
      ),
    );
  }

  Widget _payMethod(String t, String s, IconData i, VoidCallback f) {
    return InkWell(
      onTap: f,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(i, color: Colors.black87),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), Text(s, style: const TextStyle(color: Colors.black54, fontSize: 11))])),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _buildTrade() {
    return _scaffold(
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [IconButton(onPressed: () => setState(() => step = OnboardStep.pay), icon: const Icon(Icons.arrow_back, color: Colors.white)), const Text('Trade Solutions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Total', style: TextStyle(color: Colors.black54, fontSize: 12)), Text('R 1000.00', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold))]),
                  Text('Purchase details ▾', style: TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('How will you be paying today?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _payMethod('Pay with Pay', 'VISA • Credit & Cheque card', Icons.credit_card, () => _paySuccess('Card')),
            _payMethod('Instant EFT', 'Instant EFT • Bank transfer', Icons.account_balance, () => _paySuccess('Instant EFT')),
            _payMethod('Capitec Pay', 'Capitec Pay', Icons.phone_android, () => _paySuccess('Capitec Pay')),
            _payMethod('SnapScan', 'SnapScan • Scan to pay', Icons.qr_code_scanner, () => _paySuccess('SnapScan')),
            const Center(child: Text('Secured via Trade Solutions • ZAR', style: TextStyle(color: Colors.white38, fontSize: 11))),
          ],
        ),
      ),
    );
  }

  void _paySuccess(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment with $m — R1000.00 successful (DEMO - connect real gateway)')));
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => step = OnboardStep.robotKey);
    });
  }

  Widget _buildKey() {
    return _scaffold(
      Column(
        children: [
          Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: () => setState(() => step = OnboardStep.tradeSolutions), icon: const Icon(Icons.arrow_back, color: Colors.white))),
          const Spacer(),
          _logo(),
          const SizedBox(height: 20),
          const Text('ENTER ROBOT KEY', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: keyCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(hintText: 'ROBOT KEY', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: const Color(0xFF1F2937), border: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
          ),
          const SizedBox(height: 16),
          _btn(activating ? 'ACTIVATING...' : 'ACTIVATE', activating ? null : () {
            if (keyCtrl.text.trim().length < 4) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your robot key')));
              return;
            }
            setState(() => activating = true);
            robotKey = keyCtrl.text.trim();
            Future.delayed(const Duration(milliseconds: 800), () {
              if (!mounted) return;
              setState(() => activating = false);
              _finish();
            });
          }, loading: activating),
          const SizedBox(height: 12),
          const Text('Your key links your robot license to your trading account.', style: TextStyle(color: Colors.white38, fontSize: 11), textAlign: TextAlign.center),
          const Spacer(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case OnboardStep.splash:
        return _buildSplash();
      case OnboardStep.start:
        return _buildStart();
      case OnboardStep.login:
        return _buildLogin();
      case OnboardStep.pay:
        return _buildPay();
      case OnboardStep.tradeSolutions:
        return _buildTrade();
      case OnboardStep.robotKey:
        return _buildKey();
      case OnboardStep.home:
        return const KayviewHomeNative();
    }
  }
}

class KayviewHomeNative extends StatefulWidget {
  const KayviewHomeNative({super.key});
  @override
  State<KayviewHomeNative> createState() => _KayviewHomeNativeState();
}

class _KayviewHomeNativeState extends State<KayviewHomeNative> {
  bool armed = false;
  bool overlayOn = false;
  double eur = 1.0842;
  double gbp = 1.2721;
  double xau = 2341.20;
  double btc = 67420;
  double bal = 0;
  double profit = 0;
  int trades = 0;
  Timer? timer;
  final keyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        eur += 0.0001;
        gbp += 0.0001;
        xau += 0.2;
        btc += 2;
        if (armed) {
          profit += 1.2;
          bal += 0.8;
          trades += 1;
        }
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    bool granted = await FlutterOverlayWindow.isPermissionGranted();
    if (!granted) {
      final ok = await FlutterOverlayWindow.requestPermission();
      if (ok != true) return;
    }
    if (!overlayOn) {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: 'KAYVIEW CHARGER',
        overlayContent: 'KV floating',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: 72,
        width: 72,
        startPosition: OverlayPosition(20, 120),
      );
      overlayOn = true;
    }
    await FlutterOverlayWindow.shareData('START');
    setState(() => armed = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KV RUNNING - Pink = LIVE. Now open MT5.'), backgroundColor: Color(0xFFFF2E88)));
    }
  }

  Future<void> _stop() async {
    await FlutterOverlayWindow.shareData('STOP');
    setState(() => armed = false);
  }

  Future<void> _openMt5() async {
    final uri = Uri.parse('mt5://');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('MT5 not installed - tap DOWNLOAD MT5 PC')));
    }
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: const Color(0xFF11182E), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E3A5F))),
      child: child,
    );
  }

  Widget _pill(String label, String val, {Color c = Colors.white}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFF0A0A1E), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('KAYVIEW CHARGER', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 2),
              const Text('POWERED BY AMBIENT • AMBIENT HOST EA', style: TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: armed ? const Color(0xFFFF2E88) : const Color(0xFF1F2937), borderRadius: BorderRadius.circular(10)),
                child: Text(armed ? '● RUNNING - ROBOT ON • PINK = LIVE' : '● STOPPED - ROBOT OFF', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 14),
              _card(
                Column(
                  children: [
                    const Text('🤖 KAYVIEW ROBOT', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: keyCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(hintText: 'ENTER ROBOT KEY', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: const Color(0xFF1F2937), border: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _start,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2E88), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('▶ START', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _stop,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF374151), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('■ STOP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _pill('Balance', 'R ${bal.toStringAsFixed(2)}'),
                        const SizedBox(width: 8),
                        _pill('Profit', 'R ${profit.toStringAsFixed(2)}', c: const Color(0xFF00FF88)),
                        const SizedBox(width: 8),
                        _pill('Trades', '$trades'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Tap START to arm robot. KV will float over MT5.', style: TextStyle(color: Colors.white54, fontSize: 11), textAlign: TextAlign.center),
                  ],
                ),
              ),
              _card(
                Column(
                  children: [
                    const Text('📊 LIVE CHART', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _pill('EURUSD', eur.toStringAsFixed(4), c: const Color(0xFF00FF88)),
                        const SizedBox(width: 8),
                        _pill('GBPUSD', gbp.toStringAsFixed(4), c: const Color(0xFF00FF88)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _pill('XAUUSD', xau.toStringAsFixed(2), c: const Color(0xFFFFD500)),
                        const SizedBox(width: 8),
                        _pill('BTC', btc.toStringAsFixed(0), c: const Color(0xFFFF8A00)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Use floating widget for overlay chart while you trade.', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              _card(
                Column(
                  children: [
                    const Text('⚡ MT5 CONNECT', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _openMt5,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('OPEN MT5 APP', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final u = Uri.parse('https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/MetaTrader5.exe');
                          if (await canLaunchUrl(u)) await launchUrl(u, mode: LaunchMode.externalApplication);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD500), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('DOWNLOAD MT5 PC', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Tap OPEN MT5 to launch your MetaTrader 5', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              _card(
                Column(
                  children: [
                    const Text('🔑 PRIME KEYS', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your Prime Key: KV-PRIME-2026 - Active'))),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6D28D9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('VIEW MY PRIME KEY', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keys synced. Check email for new keys.'))),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6D28D9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('SYNC KEYS', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
              const Text('© 2026 KAYVIEW CHARGER\nVersion 1.0.0 • AMBIENT HOST EA', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}
