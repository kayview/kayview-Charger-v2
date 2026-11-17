import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
    final glowColor = isRunning ? const Color(0xFFFF2E88) : const Color(0xFF9CA3AF);
    final bgColor = isRunning ? const Color(0xFF1A0A1E) : const Color(0xFF1F2937);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: _toggle,
          onPanUpdate: (details) { FlutterOverlayWindow.moveOverlay(OverlayPosition(details.globalPosition.dx, details.globalPosition.dy)); },
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: bgColor, shape: BoxShape.circle,
              border: Border.all(color: glowColor, width: 2.5),
              boxShadow: isRunning
                  ? [BoxShadow(color: glowColor.withOpacity(0.85), blurRadius: 22, spreadRadius: 4), BoxShadow(color: glowColor.withOpacity(0.45), blurRadius: 40, spreadRadius: 8)]
                  : [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('KV', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 1),
                Icon(isRunning ? Icons.pause : Icons.play_arrow, color: glowColor, size: 16),
                Text(isRunning ? 'RUNNING' : 'STOPPED', style: TextStyle(color: glowColor, fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: KayviewRoot(),
    );
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
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getBool('kayview_onboarded') ?? false) && mounted) {
      setState(() => step = OnboardStep.home);
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('kayview_onboarded', true);
    await prefs.setString('kayview_email', email ?? '');
    await prefs.setString('kayview_robot_key', robotKey ?? '');
    setState(() => step = OnboardStep.home);
  }

  Widget _kvLogo({double size = 72}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white24)),
      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('KV', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
        SizedBox(height: 2),
        Text('KAYVIEW', style: TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 3)),
        Text('CHARGER', style: TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 3)),
      ]),
    );
  }

  Widget _scaffold(Widget child) {
    return Scaffold(backgroundColor: const Color(0xFF0A0A1E), body: SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: child)));
  }

  Widget _primaryBtn(String label, VoidCallback? onTap, {bool loading = false}) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6D28D9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
        child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildSplash() {
    return _scaffold(Column(children: [
      const Spacer(),
      _kvLogo(size: 110),
      const SizedBox(height: 28),
      const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('WELCOME TO', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)),
        SizedBox(width: 10),
        Text('KAYVIEW', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 6),
      const Text('CHARGER  •  HOW TO GUIDE', style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 2)),
      const SizedBox(height: 8),
      const Text('POWERED BY AMBIENT', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 3)),
      const Spacer(),
      const Text('AMBIENT HOST EA - KV - READY', style: TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 2)),
    ]));
  }

  Widget _buildStart() {
    return _scaffold(Column(children: [
      const Spacer(),
      _kvLogo(size: 90),
      const SizedBox(height: 24),
      const Text('KAYVIEW CHARGER', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1)),
      const SizedBox(height: 6),
      const Text('POWERED BY AMBIENT', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
      const Spacer(),
      _primaryBtn('START', () => setState(() => step = OnboardStep.login)),
      const SizedBox(height: 16),
    ]));
  }

  Widget _buildLogin() {
    return _scaffold(Column(children: [
      Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: () => setState(() => step = OnboardStep.start), icon: const Icon(Icons.arrow_back, color: Colors.white))),
      const Spacer(),
      _kvLogo(size: 72),
      const SizedBox(height: 20),
      const Text('LOGIN', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
      const SizedBox(height: 20),
      TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'EMAIL', hintStyle: const TextStyle(color: Colors.white38, letterSpacing: 1), filled: true, fillColor: const Color(0xFF1F2937), border: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16))),
      const SizedBox(height: 16),
      _primaryBtn(checking ? 'CHECKING...' : 'PROCEED', checking ? null : () {
        if (emailCtrl.text.trim().isEmpty || !emailCtrl.text.contains('@')) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email')));
          return;
        }
        setState(() => checking = true);
        email = emailCtrl.text.trim();
        Future.delayed(const Duration(milliseconds: 1400), () { if (!mounted) return; setState(() { checking = false; step = OnboardStep.pay; }); });
      }, loading: checking),
      const Spacer(),
    ]));
  }

  Widget _buildPay() {
    return _scaffold(SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        IconButton(onPressed: () => setState(() => step = OnboardStep.login), icon: const Icon(Icons.arrow_back, color: Colors.white)),
        const Text('Pay for App', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(onPressed: () => setState(() => step = OnboardStep.home), icon: const Icon(Icons.close, color: Colors.white54)),
      ]),
      const SizedBox(height: 12),
      Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('KAYVIEW CHARGER', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Get instant access to professional trading tool and expert advisor. Boost your trading performance.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        const Text('R1000', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
        const Text('One-time purchase • ZAR', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 12),
        const Text('✓ Professional Trading Tool\n✓ Expert Advisor (EA)\n✓ Instant Access\n✓ 24/7 Support', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
        const SizedBox(height: 16),
        Row(children: [
          Checkbox(value: agreed, activeColor: const Color(0xFF6D28D9), onChanged: (v) => setState(() => agreed = v ?? false)),
          const Expanded(child: Text('I agree to Privacy Policy, Terms of Service and Refund Policy', style: TextStyle(color: Colors.white70, fontSize: 12))),
        ]),
      ])),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: !agreed ? null : () => setState(() => step = OnboardStep.tradeSolutions), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFACC15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))), child: const Text('Buy Now', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
      const SizedBox(height: 12),
      const Center(child: Text('Copyright © 2026 All Rights Reserved. KAYVIEW CHARGER', style: TextStyle(color: Colors.white30, fontSize: 10))),
    ])));
  }

  Widget _payMethod(String title, String sub, IconData icon, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Row(children: [Icon(icon, color: Colors.black87), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)), Text(sub, style: const TextStyle(color: Colors.black54, fontSize: 11))])), const Icon(Icons.chevron_right, color: Colors.black38)])));
  }

  Widget _buildTradeSolutions() {
    return _scaffold(SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [IconButton(onPressed: () => setState(() => step = OnboardStep.pay), icon: const Icon(Icons.arrow_back, color: Colors.white)), const Text('Trade Solutions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
      const SizedBox(height: 16),
      Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Total', style: TextStyle(color: Colors.black54, fontSize: 12)), Text('R 1000.00', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold))]), Text('Purchase details ▾', style: TextStyle(color: Colors.black54, fontSize: 12))])),
      const SizedBox(height: 16),
      const Text('How will you be paying today?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _payMethod('Pay with Pay', 'VISA • Credit & Cheque card', Icons.credit_card, () => _paySuccess('Card')),
      _payMethod('Instant EFT', 'Instant EFT • Bank transfer', Icons.account_balance, () => _paySuccess('Instant EFT')),
      _payMethod('Capitec Pay', 'Capitec Pay', Icons.phone_android, () => _paySuccess('Capitec Pay')),
      _payMethod('SnapScan', 'SnapScan • Scan to pay', Icons.qr_code_scanner, () => _paySuccess('SnapScan')),
      const SizedBox(height: 8),
      const Center(child: Text('Secured via Trade Solutions • ZAR, NOT \$', style: TextStyle(color: Colors.white38, fontSize: 11))),
    ])));
  }

  void _paySuccess(String method) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment with $method — R1000.00 successful')));
    Future.delayed(const Duration(milliseconds: 800), () { if (mounted) setState(() => step = OnboardStep.robotKey); });
  }

  Widget _buildRobotKey() {
    return _scaffold(Column(children: [
      Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: () => setState(() => step = OnboardStep.tradeSolutions), icon: const Icon(Icons.arrow_back, color: Colors.white))),
      const Spacer(),
      _kvLogo(size: 72),
      const SizedBox(height: 20),
      const Text('ENTER ROBOT KEY', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
      const SizedBox(height: 20),
      TextField(controller: keyCtrl, style: const TextStyle(color: Colors.white, letterSpacing: 1), decoration: InputDecoration(hintText: 'ROBOT KEY', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: const Color(0xFF1F2937), border: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16))),
      const SizedBox(height: 16),
      _primaryBtn(activating ? 'ACTIVATING...' : 'ACTIVATE', activating ? null : () {
        if (keyCtrl.text.trim().length < 4) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your robot key')));
          return;
        }
        setState(() => activating = true);
        robotKey = keyCtrl.text.trim();
        Future.delayed(const Duration(milliseconds: 1400), () { if (!mounted) return; setState(() => activating = false); _finishOnboarding(); });
      }, loading: activating),
      const SizedBox(height: 12),
      const Text('Your key links your robot license to your trading account.', style: TextStyle(color: Colors.white38, fontSize: 11), textAlign: TextAlign.center),
      const Spacer(),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case OnboardStep.splash: return _buildSplash();
      case OnboardStep.start: return _buildStart();
      case OnboardStep.login: return _buildLogin();
      case OnboardStep.pay: return _buildPay();
      case OnboardStep.tradeSolutions: return _buildTradeSolutions();
      case OnboardStep.robotKey: return _buildRobotKey();
      case OnboardStep.home: return const KayviewWeb();
    }
  }
}

class KayviewWeb extends StatefulWidget {
  const KayviewWeb({super.key});
  @override
  State<KayviewWeb> createState() => _KayviewWebState();
}

class _KayviewWebState extends State<KayviewWeb> {
  late final WebViewController controller;
  bool loading = true;
  bool hasError = false;
  bool overlayOn = false;
  final String remoteKeysUrl = 'https://kayview-api.onrender.com/prime-keys.html';

  Future<void> openOutside(String link) async {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void loadFresh() {
    setState(() { loading = true; hasError = false; });
    controller.loadFlutterAsset('assets/index.html');
  }

  Future<void> _onStartPressed() async {
    bool granted = await FlutterOverlayWindow.isPermissionGranted();
    if (!granted) {
      final ok = await FlutterOverlayWindow.requestPermission();
      if (ok != true) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Allow "Display over other apps" to keep KV floating over MT5')));
        return;
      }
    }
    if (!overlayOn) {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: 'KAYVIEW CHARGER',
        overlayContent: 'KV floating - Tap PLAY/STOP',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: 72, width: 72,
        startPosition: OverlayPosition(20, 120),
      );
      setState(() => overlayOn = true);
    }
    await FlutterOverlayWindow.shareData('START');
    HapticFeedback.mediumImpact();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KV floating over apps - Pink = RUNNING. Drag it. Tap = PLAY/STOP. Stays over MT5.'), backgroundColor: Color(0xFFFF2E88)));
  }

  Future<void> _onStopPressed() async {
    await FlutterOverlayWindow.shareData('STOP');
  }

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(false)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 KAYVIEW-CHARGER/1.0')
      ..setBackgroundColor(const Color(0xFF020617))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() { loading = true; hasError = false; }),
          onPageFinished: (_) async {
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) setState(() => loading = false);
            controller.runJavaScript('''
              (function(){
                if(window.__kayviewHooked) return; window.__kayviewHooked = true;
                try{ localStorage.setItem('kayview_onboarded','1'); }catch(e){}
                document.addEventListener('click', function(e){
                  var t = e.target && e.target.closest ? e.target.closest('button') : null;
                  if(!t) return;
                  var txt = (t.innerText||'').toUpperCase();
                  if(txt.includes('START')){ KayviewBridge.postMessage('START'); }
                  if(txt.includes('STOP') || txt.includes('REMOVE')){ KayviewBridge.postMessage('STOP'); }
                });
              })();
            ''');
          },
          onWebResourceError: (e) {
            setState(() { loading = false; hasError = true; });
          },
          onNavigationRequest: (request) {
            final u = request.url;
            if (u.startsWith('mt5://')) {
              openOutside(u);
              return NavigationDecision.prevent;
            }
            if (u.contains('wa.me') || u.contains('whatsapp') || u.contains('api.whatsapp') || u.startsWith('tel:') || u.startsWith('mailto:') || u.contains('t.me')) {
              openOutside(u);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel('KayviewBridge', onMessageReceived: (msg) async {
        if (msg.message == 'START') await _onStartPressed();
        else if (msg.message == 'STOP') await _onStopPressed();
      })
      ..loadFlutterAsset('assets/index.html');

    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data == 'OVERLAY_STOPPED') {
        controller.runJavaScript("if(typeof armed!=='undefined' && armed && window.toggleBot){ toggleBot(); }");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: controller),
            Positioned(
              right: 16, bottom: 16,
              child: FloatingActionButton.small(
                backgroundColor: Colors.black,
                onPressed: loadFresh,
                child: const Icon(Icons.refresh, color: Colors.white),
              ),
            ),
            if (loading)
              Container(
                color: Colors.white,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.black),
                      SizedBox(height: 12),
                      Text('WAKING UP KAYVIEW...', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ],
                  ),
                ),
              ),
            if (hasError)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.black, size: 50),
                    const SizedBox(height: 12),
                    const Text('Could not load', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: loadFresh,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                      child: const Text('TAP TO RETRY'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
