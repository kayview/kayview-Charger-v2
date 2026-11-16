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
    controller.loadRequest(
      Uri.parse('$url?v=${DateTime.now().millisecondsSinceEpoch}'),
    );
  }

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(false)
      // PRETEND TO BE CHROME - this is the fix for blank page
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            loading = true;
            hasError = false;
          }),
          onPageFinished: (_) async {
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) setState(() => loading = false);
          },
          onWebResourceError: (e) {
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
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: controller),

            Positioned(
              right: 16,
              bottom: 16,
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
                      Text(
                        'WAKING UP KAYVIEW...',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
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
