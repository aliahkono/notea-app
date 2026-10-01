import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'controllers/controllers.dart';
import 'controllers/pet_controller.dart';
import 'controllers/study_material_controller.dart';
import 'models/pet.dart';
import 'screens/splash_screen.dart';
import 'services/database_manager.dart';
import 'services/storage.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
  ));

  final db = DatabaseManager();
  final pet = PetController();
  final pomodoro = PomodoroController()
    ..onWorkSessionComplete = (minutes) => pet.reward(PetReward.focus, focusMinutes: minutes);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DatabaseManager>.value(value: db),
        ChangeNotifierProvider<PetController>.value(value: pet),
        ChangeNotifierProvider<PomodoroController>.value(value: pomodoro),
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => NotesController(db)),
        ChangeNotifierProvider(create: (_) => TaskController()),
        ChangeNotifierProvider(create: (_) => JournalController()),
        ChangeNotifierProvider(create: (_) => BlurtController()),
        ChangeNotifierProvider(create: (_) => StudyMaterialsController()),
        ChangeNotifierProvider(create: (_) => FeynmanController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
      ],
      child: const NoteaApp(),
    ),
  );
}

class NoteaApp extends StatelessWidget {
  const NoteaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeManager>().selectedTheme;
    return MaterialApp(
      title: 'Notea',
      debugShowCheckedModeBanner: false,
      theme: buildNoteaTheme(theme),
      home: const SplashScreen(),
    );
  }
}