import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'pages/app_start.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initTimezone();
  await _initNotifications();

  runApp(const MyApp());
}

/// 🔔 تهيئة الإشعارات
Future<void> _initNotifications() async {
  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const settings = InitializationSettings(
    android: androidSettings,
  );

  await notificationsPlugin.initialize(settings);
}

/// 🌍 تهيئة التوقيت
Future<void> _initTimezone() async {
  tz.initializeTimeZones();
  //final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  //tz.setLocalLocation(tz.getLocation(timeZoneName));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AppStartPage(), // هنا يجب أن تشير إلى الصفحة التي تريد أن تبدأ منها
      debugShowCheckedModeBanner: false,
    );
  }
}





