import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
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
        fontFamily: 'Roboto',
      ),
      home: const AppLoader(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? SplashScreen(
            onInitializationComplete: () {
              setState(() {
                _isLoading = false;
              });
            },
          )
        : const HomeScreen();
  }
}