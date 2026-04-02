// فایلی سەرەکی ئەپەکە - لێرەوە ئەپەکە دەست پێ دەکات
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ڕێکخستنی ئاگادارییەکان (Notifications)
  await NotificationService.initialize();

  runApp(const WisdomApp());
}

class WisdomApp extends StatelessWidget {
  const WisdomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wisdom Quotes',
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
