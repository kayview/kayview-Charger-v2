import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

@pragma('vm:entry-point')
void overlayMain() {
  runApp(const MaterialApp(home: OverlayBall(), debugShowCheckedModeBanner: false));
}

class OverlayBall extends StatefulWidget {
  const OverlayBall({super.key});
  @override
  State<OverlayBall> createState() => _OverlayBallState();
}

class _OverlayBallState extends State<OverlayBall> {
  bool running = true;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data == 'running') setState(() => running = true);
      if (data == 'stopped') setState(() => running = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: GestureDetector(
          onTap: () {
            setState(() => running = !running);
            FlutterOverlayWindow.shareData(running ? 'running' : 'stopped');
          },
          onPanUpdate: (d) {
            FlutterOverlayWindow.moveOverlay(OverlayPosition(d.globalPosition.dx - 29, d.globalPosition.dy - 29));
          },
          child: Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: running ? Colors.pink : Colors.grey,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: running ? Colors.pink : Colors.grey, blurRadius: 18)],
            ),
            alignment: Alignment.center,
            child: Text(running ? '■' : '▶', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
          ),
        ),
      ),
    );
  }
}
