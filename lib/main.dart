import 'package:flutter/material.dart';
import 'package:stream_sync/SplashScreen.dart';

void main() => runApp(new BluetoothControlApplication());

class BluetoothControlApplication extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen()
    );
  }
}
