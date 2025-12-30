import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/weather_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/note_provider.dart';
import 'services/database_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('cache');

  final dbInitializer = DatabaseInitializer();
  await dbInitializer.initializeIfEmpty();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WeatherProvider()..bootstrap()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
      ],
      child: const WeatherCalendarApp(),
    ),
  );
}
