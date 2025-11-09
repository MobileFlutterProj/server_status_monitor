import 'package:flutter/material.dart';
import '../services/server_monitor_service.dart';

class AddServerDialog extends StatefulWidget {
  final ServerConfig? server;
  final Function(ServerConfig) onSave;

  const AddServerDialog({
    super.key,
    this.server,
    required this.onSave,
  });

  @override
  State<AddServerDialog> createState() => _AddServerDialogState();
}

class _AddServerDialogState extends State<AddServerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.server != null;
    
    if (_isEditing) {
      _nameController.text = widget.server!.name;
      _hostController.text = widget.server!.host;
      _portController.text = widget.server!.port.toString();
      _usernameController.text = widget.server!.username;
      _passwordController.text = widget.server!.password;
    }
  }

  void _saveServer() {
    if (_formKey.currentState!.validate()) {
      final config = ServerConfig(
        id: _isEditing ? widget.server!.id : null,
        name: _nameController.text,
        host: _hostController.text,
        port: int.tryParse(_portController.text) ?? 22,
        username: _usernameController.text,
        password: _passwordController.text,
      );
      
      widget.onSave(config);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Редактировать сервер' : 'Добавить сервер',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isEditing 
                  ? 'Измените данные подключения к серверу'
                  : 'Введите данные для подключения к серверу',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Название сервера',
                      hintText: 'Мой сервер',
                      icon: Icons.computer,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите название сервера';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _hostController,
                      label: 'IP адрес или домен',
                      hintText: '192.168.1.100 или example.com',
                      icon: Icons.language,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите адрес сервера';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _portController,
                      label: 'SSH порт',
                      hintText: '22',
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите порт';
                        }
                        final port = int.tryParse(value);
                        if (port == null || port <= 0 || port > 65535) {
                          return 'Введите корректный порт (1-65535)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Имя пользователя',
                      hintText: 'user',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите имя пользователя';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Пароль',
                      hintText: 'password',
                      icon: Icons.lock,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите пароль';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Подсказка для тестирования
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Для тестирования:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• test.rebex.net:22 (demo/password)\n'
                      '• Локальный сервер: 127.0.0.1:22',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveServer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_isEditing ? 'Сохранить' : 'Добавить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}