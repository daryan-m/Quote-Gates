import 'package:flutter/material.dart';
import 'package:wisdom_app/services/purchase_service.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await PurchaseService.instance.initialize();
  runApp(const WisdomApp());
}

class WisdomApp extends StatelessWidget {
  const WisdomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wisdom Gates',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'System',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
