import 'package:flutter/material.dart';
import 'package:server_status_monitor/services/server_monitor_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final monitorService = ServerMonitorService();
  await monitorService.loadServers(); // ← Загружаем сохранённые серверы
  runApp(MyApp(monitorService: monitorService));
}

class MyApp extends StatelessWidget {
  final ServerMonitorService monitorService; // ← добавьте поле

  const MyApp({super.key, required this.monitorService}); // ← добавьте параметр

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Server Status Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: AppLoader(monitorService: monitorService), // ← передайте в AppLoader
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppLoader extends StatefulWidget {
  final ServerMonitorService monitorService; // ← добавьте поле

  const AppLoader({super.key, required this.monitorService}); // ← добавьте параметр

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
        : HomeScreen(monitorService: widget.monitorService); // ← передайте в HomeScreen
  }
}