import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:visage/firebase_options.dart';
import 'view/Home/visage_home_view.dart';

/*
firebase login
firebase init

Build & Deploy Commands:
flutter run --web-renderer html canvaskit --dart-define=FLUTTER_WEB_USE_SKIA=true
flutter build web --web-renderer canvaskit --dart-define=FLUTTER_WEB_USE_SKIA=true
flutter run -d chrome --web-browser-flag "--disable-web-security"
flutter build web --web-renderer canvaskit --dart-define=FLUTTER_WEB_USE_SKIA=true --release
flutter build web --wasm --no-wasm-dry-run

firebase use nyx-0001
firebase deploy --only hosting:visageu

Other commands:
flutter run -d chrome --profile
flutter pub upgrade --major-versions
gsutil cors set cors.json gs://lu-stock.appspot.com
*/

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visage - AI Comp Card Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const VisageHomeView(),
    );
  }
}
