import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ServerMonitorApp());
}

class ServerMonitorApp extends StatelessWidget {
  const ServerMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Server Status Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}