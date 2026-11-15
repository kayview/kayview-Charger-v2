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

  Future<void> openOutside(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => loading = false),
          onNavigationRequest: (request) {
            final url = request.url;

            // WhatsApp, phone, email, Telegram - open OUTSIDE WebView
            if (url.contains('wa.me') ||
                url.contains('whatsapp') ||
                url.contains('api.whatsapp') ||
                url.startsWith('tel:') ||
                url.startsWith('mailto:') ||
                url.contains('t.me')) {
              openOutside(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://kayview-api.onrender.com/prime-keys.html'),
      );
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
                      'KAYVIEW...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
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
