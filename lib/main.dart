import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const KayviewApp());

class KayviewApp extends StatelessWidget {
  const KayviewApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: KayviewWeb(),
    );
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

  final String url = 'https://kayview-api.onrender.com/prime-keys.html';

  Future<void> openOutside(String link) async {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void loadFresh() {
    setState(() {
      loading = true;
      hasError = false;
    });
    controller.clearCache();
    controller.loadRequest(
      Uri.parse('$url?v=${DateTime.now().millisecondsSinceEpoch}'),
    );
  }

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            loading = true;
            hasError = false;
          }),
          onPageFinished: (_) => setState(() => loading = false),
          onWebResourceError: (error) {
            // Auto-retry once on CACHE_MISS, don't show Android error page
            if (error.errorCode == -1 || error.description.contains('CACHE')) {
              loadFresh();
              return;
            }
            setState(() {
              loading = false;
              hasError = true;
            });
          },
          onNavigationRequest: (request) {
            final u = request.url;
            if (u.contains('wa.me') ||
                u.contains('whatsapp') ||
                u.contains('api.whatsapp') ||
                u.startsWith('tel:') ||
                u.startsWith('mailto:') ||
                u.contains('t.me')) {
              openOutside(u);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    // THIS is the real fix - wipe old poisoned cache before first load
    controller.clearCache().then((_) {
      controller.loadRequest(Uri.parse(url));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: controller),
            if (loading)
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'WAKING UP KAYVIEW...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            if (hasError)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 50),
                    const SizedBox(height: 12),
                    const Text('Could not load', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: loadFresh,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
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
