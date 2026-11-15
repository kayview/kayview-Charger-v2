import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const KayviewApp());

class KayviewApp extends StatelessWidget {
  const KayviewApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KAYVIEW',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB))),
      home: const LandingScreen(),
    );
  }
}

const String API_HOST = 'kayview-api.onrender.com';
const String API = 'https://kayview-api.onrender.com';
const String WEB_URL = 'https://kayview-api.onrender.com/prime-keys.html';
const String WA_URL = 'https://wa.me/27730819637?text=Hi%20KAYVIEW%2C%20I%20paid%20for%20a%20key';

Future<void> openWeb() async {
  final uri = Uri.parse(WEB_URL);
  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
}
Future<void> openWhatsApp() async {
  final uri = Uri.parse(WA_URL);
  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

// ===== BUILT-IN DNS - bypasses bad WiFi DNS, like Chrome does =====
Future<String> _dohIp() async {
  final r = await http.get(Uri.parse('https://dns.google/resolve?name=$API_HOST&type=A')).timeout(const Duration(seconds: 10));
  final d = jsonDecode(r.body);
  final ans = d['Answer'] as List;
  return ans.first['data'] as String; // e.g. 216.24.57.x
}

Future<String> _rawRequest(String method, String path, {Map<String, dynamic>? body}) async {
  final ip = await _dohIp(); // DNS over HTTPS, not your router
  final socket = await Socket.connect(ip, 443, timeout: const Duration(seconds: 10));
  final secure = await SecureSocket.secure(socket, host: API_HOST); // SNI = real domain
  final bodyStr = body == null ? '' : jsonEncode(body);
  final req = StringBuffer();
  req.write('$method $path HTTP/1.0\r\n');
  req.write('Host: $API_HOST\r\n');
  req.write('Content-Type: application/json\r\n');
  req.write('Accept: application/json\r\n');
  req.write('Connection: close\r\n');
  req.write('Content-Length: ${utf8.encode(bodyStr).length}\r\n\r\n');
  req.write(bodyStr);
  secure.write(req.toString());
  await secure.flush();
  final bytes = await secure.fold<List<int>>([], (a, b) => a..addAll(b)).timeout(const Duration(seconds: 20));
  await secure.close();
  final full = utf8.decode(bytes, allowMalformed: true);
  final idx = full.indexOf('\r\n\r\n');
  if (idx == -1) throw Exception('Bad response');
  return full.substring(idx + 4);
}

// ============ LANDING ============
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)), child: const Center(child: Text('K', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)))),
                      const SizedBox(width: 10),
                      const Text('KAYVIEW • Ambient Host', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(99)), child: const Text('● Cloud Live', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold))),
                    ]),
                    const SizedBox(height: 22),
                    const Text('KAYVIEW • INSTITUTIONAL TRADING • ZAR', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    const Text('Your EA, running\neven when you sleep.', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.05)),
                    const SizedBox(height: 10),
                    const Text('KAYVIEW turns your phone into a 24/7 hosting cloud. No PC. No VPS. Just connect MT4 / MT5 and go live.', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.5)),
                    const SizedBox(height: 20),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LicenseScreen())), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))), child: const Text('↗ Open an account — Verify Key', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: OutlinedButton(onPressed: openWeb, style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))), child: const Text('☁️ Open Web', style: TextStyle(color: Colors.white)))),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LicenseScreen())), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))), child: const Text('Sign in →', style: TextStyle(color: Colors.white)))),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _InfoCard(title: '☁️ Cloud Hosting — Like Gizmo Pro', desc: 'Connect your MT4/MT5 login, tap Start Hosting, close your phone. Your EA keeps trading on KAYVIEW Cloud.', btnText: 'Start Hosting →', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LicenseScreen()))),
              _PlanCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title, desc, btnText; final VoidCallback onTap;
  const _InfoCard({required this.title, required this.desc, required this.btnText, required this.onTap});
  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 6), Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)), if (btnText.isNotEmpty) ...[const SizedBox(height: 12), ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))), child: Text(btnText, style: const TextStyle(color: Colors.white)))]]));
}

class _PlanCard extends StatelessWidget {
  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('PLANS', style: TextStyle(fontWeight: FontWeight.bold)),
    const Text('Simple pricing. Serious tools.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    const SizedBox(height: 12),
    _PlanRow(name: 'Student', price: 'R299', per: '/ month', features: '✓ 1 bot hosted 24/7\n✓ No PC, No VPS\n✓ Sniper AI scanner'),
    _PlanRow(name: 'Mentor', price: 'R1 499', per: '/ month • MOST POPULAR', features: '✓ Unlimited bot builds\n✓ Issue student keys\n✓ Host students 24/7', highlight: true),
    _PlanRow(name: 'Single Key', price: 'R100', per: '/ key • Pay once', features: '✓ 1 KAYVIEW Key • 30 days\n✓ Use in APK + MT5 EA\n✓ TymeBank • Fast approval'),
    const SizedBox(height: 8),
    SizedBox(width: double.infinity, child: OutlinedButton(onPressed: openWeb, child: const Text('Buy Key on Web →'))),
  ]));
}

class _PlanRow extends StatelessWidget {
  final String name, price, per, features; final bool highlight;
  const _PlanRow({required this.name, required this.price, required this.per, required this.features, this.highlight = false});
  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: highlight ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC), border: Border.all(color: highlight ? const Color(0xFFBFDBFE) : Colors.transparent), borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold)), Text(price, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)), Text(per, style: const TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 6), Text(features, style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF475569)))]));
}

// ============ LICENSE ============
class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});
  @override State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final emailCtrl = TextEditingController();
  final keyCtrl = TextEditingController();
  String status = '';
  bool loading = false;

  Future<void> verifyKey() async {
    final email = emailCtrl.text.trim();
    final key = keyCtrl.text.trim().toUpperCase();
    if (email.isEmpty || key.isEmpty) { setState(() => status = 'Enter email + license key'); return; }
    setState(() { loading = true; status = 'Waking KAYVIEW Cloud...'; });
    try {
      // Try normal way first (fast), then built-in DNS way
      String bodyStr;
      try {
        final res = await http.post(Uri.parse('$API/api/verify-key'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'key': key})).timeout(const Duration(seconds: 12));
        bodyStr = res.body;
      } catch (_) {
        setState(() => status = 'WiFi DNS blocked — using built-in DNS...');
        bodyStr = await _rawRequest('POST', '/api/verify-key', body: {'email': email, 'key': key});
      }
      final data = jsonDecode(bodyStr);
      if (data['valid'] == true || data['success'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardScreen(email: email, licenseKey: key)));
        return;
      } else {
        setState(() => status = '❌ ${data['reason'] ?? 'Key not found — Check Key Shop'}');
      }
    } catch (e) {
      setState(() => status = '❌ Cant reach server. Error: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(title: const Text('KAYVIEW — Login'), backgroundColor: Colors.white),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: Column(children: [
          Container(width: 52, height: 52, decoration: const BoxDecoration(color: Color(0xFF0F172A), shape: BoxShape.circle), child: const Center(child: Text('K', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)))),
          const SizedBox(height: 10),
          const Text('Welcome back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const Text('Login to KAYVIEW', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 18),
          const Align(alignment: Alignment.centerLeft, child: Text('Email (same as Web login)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          const SizedBox(height: 6),
          TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: 'kayview051@gmail.com', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
          const SizedBox(height: 14),
          const Align(alignment: Alignment.centerLeft, child: Text('License Key (from Web > Keys)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          const SizedBox(height: 6),
          TextField(controller: keyCtrl, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(hintText: 'KV-XXXX-XXXX', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: loading ? null : verifyKey, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))), child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Verify License Key', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: openWeb, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))), child: const Text('Buy Key on Web →'))),
          if (status.isNotEmpty) ...[const SizedBox(height: 12), Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))],
        ])),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('No key yet?', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('1. Tap Buy Key on Web\n2. Login > Key Shop > Pay R100 to TymeBank 51107457045\n3. Send proof on WhatsApp +27 73 081 9637', style: TextStyle(fontSize: 13, height: 1.6, color: Colors.grey)),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: openWhatsApp, icon: const Text('🟢'), label: const Text('Send Proof on WhatsApp', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))))),
        ])),
      ])),
    );
  }
}

// ============ DASHBOARD ============
class DashboardScreen extends StatefulWidget {
  final String email; final String licenseKey;
  const DashboardScreen({super.key, required this.email, required this.licenseKey});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int idx = 0;
  String cloudStatus = 'Checking...';
  @override void initState() { super.initState(); checkCloud(); }
  Future<void> checkCloud() async {
    try {
      final b = await _rawRequest('GET', '/api/meta');
      final d = jsonDecode(b);
      setState(() => cloudStatus = 'ONLINE • ${d['keys'] ?? 6} keys');
    } catch (_) {
      try {
        final r = await http.get(Uri.parse('$API/api/meta')).timeout(const Duration(seconds: 10));
        final d = jsonDecode(r.body);
        setState(() => cloudStatus = 'ONLINE • ${d['keys'] ?? 6} keys');
      } catch (_) { setState(() => cloudStatus = 'Offline — Check internet'); }
    }
  }
  @override Widget build(BuildContext context) {
    final pages = [
      SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Welcome back,', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        Text(widget.email, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 14),
        Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF2563EB)]), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('KAYVIEW Cloud — $cloudStatus', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Your EA keeps running 24/7.', style: TextStyle(color: Colors.white70)), const SizedBox(height: 10), ElevatedButton(onPressed: () => setState(() => idx = 2), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))), child: const Text('▶ Start Hosting', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))])),
      ])),
      SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('🔑 Your Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 6), Text(widget.licenseKey, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB), fontSize: 16)), Text(widget.email, style: const TextStyle(color: Colors.grey))]))])),
      SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('☁️ Cloud Hosting', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), const Text('Run your EA 24/7 — No PC, No VPS.', style: TextStyle(color: Colors.grey)), const SizedBox(height: 12), Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Start New Hosting Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 12), _Field(label: 'Your KAYVIEW Key', initial: widget.licenseKey), _Field(label: 'MT4 / MT5 Login', hint: 'e.g. 12345678'), _Field(label: 'MT Server', hint: 'e.g. Deriv-Server'), const SizedBox(height: 8), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hosting STARTED ✓ Your EA is ONLINE 24/7'))); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))), child: const Text('▶ Start Hosting 24/7', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))]))])),
      SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(children: [const Text('R100', style: TextStyle(color: Color(0xFF2563EB), fontSize: 36, fontWeight: FontWeight.w800)), const Text('TymeBank 51107457045', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: openWeb, child: const Text('Buy in Key Shop on Web →'))), const SizedBox(height: 8), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: openWhatsApp, icon: const Text('🟢'), label: const Text('Send Proof on WhatsApp', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))))]))])),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(title: const Text('KAYVIEW • Mentor Console'), backgroundColor: Colors.white),
      body: pages[idx],
      bottomNavigationBar: NavigationBar(selectedIndex: idx, onDestinationSelected: (i) => setState(() => idx = i), destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: 'Overview'),
        NavigationDestination(icon: Icon(Icons.key), label: 'Keys'),
        NavigationDestination(icon: Icon(Icons.cloud), label: 'Hosting'),
        NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Key Shop'),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final String label; final String? hint; final String? initial;
  const _Field({required this.label, this.hint, this.initial});
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 6), TextField(controller: initial != null ? TextEditingController(text: initial) : null, decoration: InputDecoration(hintText: hint ?? '', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))), const SizedBox(height: 12)]);
}
