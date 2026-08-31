import 'package:flutter/material.dart';
import 'core/theme/colors.dart';
import 'features/auth/view/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EquipmentManagementApp());
}

class EquipmentManagementApp extends StatelessWidget {
  const EquipmentManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Equipment Management System',
      theme: AppColors.theme,
      home: const LoginPage(),
    );
  }
}
