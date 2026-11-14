import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

// ============================================================
// KAYVIEW CHARGER - POWERED BY AMBIENT
// AMBIENT HOST EA - KV - READY
// SYSTEM OVERLAY - draws over other apps, NOT inside the app.
//
// FLOW:
// Press START in KAYVIEW CHARGER > phone asks "Allow display over other apps?"
// > you allow it > KV logo floats on top, even when you leave app and open MT5.
// - Drag it anywhere
// - Tap it = PLAY / STOP
// - Pink glow when RUNNING, grey when STOPPED
// - Stays over MT5 while bot is running
//
// API is BACKEND ONLY - never in UI.
// VOL_20 / VOL_80 / VOL_88 are plain pairs, NOT Deriv.
// ============================================================

// ---------- OVERLAY ENTRY POINT - must be separate ----------
@pragma('vm:entry-point')
void overlayMain() {
  runApp(const OverlayApp());
}

class OverlayApp extends StatefulWidget {
  const OverlayApp({super.key});
  @override
  State<OverlayApp> createState() => _OverlayAppState();
}

class _OverlayAppState extends State<OverlayApp> {
  bool isRunning = true; // starts RUNNING when START pressed
  Offset dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    // Listen for data from main app (START / STOP)
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is String) {
        if (data == 'STOP') setState(() => isRunning = false);
        if (data == 'START' || data == 'RUNNING') setState(() => isRunning = true);
      }
    });
  }

  void _toggle() {
    setState(() => isRunning = !isRunning);
    // Tell main app - it will also update WebView bot state
    FlutterOverlayWindow.shareData(isRunning ? 'OVERLAY_RUNNING' : 'OVERLAY_STOPPED');
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    // Pink glow when RUNNING, grey when STOPPED - exactly as you asked
    final glowColor = isRunning ? const Color(0xFFFF2E88) : const Color(0xFF9CA3AF);
    final bgColor = isRunning ? const Color(0xFF1A0A1E) : const Color(0xFF1F2937);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: _toggle,
          // Drag anywhere - overlay window moves with finger
          onPanUpdate: (details) {
            // Move the system window itself
            FlutterOverlayWindow.moveOverlay(details.globalPosition);
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: glowColor, width: 2.5),
              boxShadow: isRunning
                  ? [
                      BoxShadow(color: glowColor.withOpacity(0.85), blurRadius: 22, spreadRadius: 4),
                      BoxShadow(color: glowColor.withOpacity(0.45), blurRadius: 40, spreadRadius: 8),
                    ]
                  : [
                      BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, spreadRadius: 1),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'KV',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    shadows: isRunning
                        ? [Shadow(color: glowColor, blurRadius: 12)]
                        : [],
                  ),
                ),
                const SizedBox(height: 1),
                Icon(
                  isRunning ? Icons.pause : Icons.play_arrow,
                  color: glowColor,
                  size: 16,
                ),
                Text(
                  isRunning ? 'RUNNING' : 'STOPPED',
                  style: TextStyle(
                    color: glowColor,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- MAIN APP ----------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KayviewApp());
}

class KayviewApp extends StatelessWidget {
  const KayviewApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KAYVIEW CHARGER',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF020617),
        primaryColor: const Color(0xFF0A2A6E),
      ),
      home: const KayviewHome(),
    );
  }
}

class KayviewHome extends StatefulWidget {
  const KayviewHome({super.key});
  @override
  State<KayviewHome> createState() => _KayviewHomeState();
}

class _KayviewHomeState extends State<KayviewHome> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _overlayOn = false;
  bool _botRunning = false;

  static const String backendApiKey = 'guest:guest';
  static const String backendDerivAppId = '1089';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF020617))
      ..setUserAgent('Mozilla/5.0 (Linux; Android 13; Median) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 KAYVIEW-CHARGER/1.0 AMBIENT-HOST-EA')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() => _loading = false);
            // Bridge: when START/STOP pressed inside WebView HTML, notify Flutter
            // We inject a hook that watches the bot button
            _controller.runJavaScript('''
              (function(){
                if(window.__kayviewHooked) return; window.__kayviewHooked = true;
                // Watch for START clicks - original toggleBot is in index.html
                document.addEventListener('click', function(e){
                  var t = e.target && e.target.closest ? e.target.closest('button') : null;
                  if(!t) return;
                  var txt = (t.innerText||'').toUpperCase();
                  if(txt.includes('START')){ KayviewBridge.postMessage('START'); }
                  if(txt.includes('STOP') || txt.includes('REMOVE')){ KayviewBridge.postMessage('STOP'); }
                  if(txt.includes('EXECUTE')){ KayviewBridge.postMessage('EXECUTE'); }
                });
              })();
            ''');
          },
          onNavigationRequest: (req) async {
            final url = req.url;
            if (url.startsWith('mt5://')) {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'KayviewBridge',
        onMessageReceived: (msg) async {
          final m = msg.message;
          if (m == 'START') {
            await _onStartPressed();
          } else if (m == 'STOP') {
            await _onStopPressed();
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(m), backgroundColor: const Color(0xFF0A2A6E)),
              );
            }
          }
        },
      )
      ..loadFlutterAsset('assets/index.html');

    // Listen for overlay taps (PLAY/STOP from floating logo)
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data == 'OVERLAY_STOPPED') {
        setState(() => _botRunning = false);
        _controller.runJavaScript("if(window.toggleBot && typeof armed!=='undefined' && armed){ toggleBot(); }");
      } else if (data == 'OVERLAY_RUNNING') {
        setState(() => _botRunning = true);
      }
    });
  }

  // --- SYSTEM OVERLAY: Press START > asks "Allow display over other apps?" > floats over MT5 ---
  Future<void> _onStartPressed() async {
    setState(() => _botRunning = true);

    bool granted = await FlutterOverlayWindow.isPermissionGranted();
    if (!granted) {
      // This is the system dialog: "Allow display over other apps?"
      final ok = await FlutterOverlayWindow.requestPermission();
      if (ok != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Allow "Display over other apps" to keep KV floating over MT5')),
          );
        }
        return;
      }
    }

    if (!_overlayOn) {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: 'KAYVIEW CHARGER',
        overlayContent: 'KV floating - Tap PLAY/STOP',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: 72,
        width: 72,
        startPosition: OverlayPosition(20, 120),
      );
      setState(() => _overlayOn = true);
    }
    // Tell overlay: RUNNING = pink glow
    await FlutterOverlayWindow.shareData('START');
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KV floating over apps - Pink = RUNNING. Drag it anywhere. Tap = PLAY/STOP. It stays over MT5.'), backgroundColor: Color(0xFFFF2E88)),
      );
    }
  }

  Future<void> _onStopPressed() async {
    setState(() => _botRunning = false);
    await FlutterOverlayWindow.shareData('STOP');
    // Keep overlay visible but grey = STOPPED, like you asked. Close only if user long-presses? Keep it so they can tap to resume.
    // If you want it to disappear on STOP, uncomment next line:
    // await FlutterOverlayWindow.closeOverlay(); setState(() => _overlayOn = false);
  }

  Future<void> _closeOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
    setState(() => _overlayOn = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0A2A6E)),
                    SizedBox(height: 12),
                    Text('KAYVIEW CHARGER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    SizedBox(height: 4),
                    Text('POWERED BY AMBIENT', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 2)),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_overlayOn)
            FloatingActionButton.small(
              heroTag: 'closeOverlay',
              backgroundColor: Colors.grey[800],
              onPressed: _closeOverlay,
              child: const Icon(Icons.close, color: Colors.white),
            ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'reload',
            backgroundColor: const Color(0xFF0A2A6E),
            onPressed: () => _controller.reload(),
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
