import 'package:flutter/services.dart';

class NativeSSHClient {
  static const MethodChannel _channel = MethodChannel('com.example.test_app/ssh');

  /// Выполняет SSH-команду и возвращает stdout как строку.
  /// Бросает PlatformException при ошибке.
  static Future<String> execute({
    required String host,
    required int port,
    required String username,
    required String password,
    required String command,
  }) async {
    final result = await _channel.invokeMethod('execute', {
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'command': command,
    });
    return result as String;
  }
}