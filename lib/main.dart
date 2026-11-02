import 'package:flutter/material.dart';
import 'services/store.dart';
import 'screens/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Keefy TV', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C5CFC), brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF090D18),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF090D18), centerTitle: false),
      cardTheme: CardThemeData(color: const Color(0xFF151C2D), elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF151C2D),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
    builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    home: const HomeScreen(),
  );
}
