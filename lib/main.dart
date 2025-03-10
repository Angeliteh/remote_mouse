import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/app_theme.dart';
import 'screens/ip_config_screen.dart';

void main() {
  // Configuración básica
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  runApp(const MyApp());
}
 
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mouse Remoto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(),
      home: const IPConfigScreen(),
    );
  }
}