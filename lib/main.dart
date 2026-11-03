import 'package:flutter/material.dart';
import 'services/store.dart';
import 'screens/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  runApp(const App());
}

const _accent = Color(0xFFF2A33A);
const _background = Color(0xFF0E1218);
const _surface = Color(0xFF171D26);

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Keefy TV',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: _accent, brightness: Brightness.dark, surface: _surface),
      scaffoldBackgroundColor: _background,
      appBarTheme: const AppBarTheme(backgroundColor: _background, centerTitle: false, elevation: 0),
      cardTheme: CardThemeData(color: _surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      navigationBarTheme: NavigationBarThemeData(backgroundColor: _surface, indicatorColor: _accent.withOpacity(.2)),
      chipTheme: ChipThemeData(
        backgroundColor: _surface,
        selectedColor: _accent.withOpacity(.22),
        side: BorderSide(color: Colors.white.withOpacity(.07)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _accent, width: 1.3)),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: _accent,
        labelColor: _accent,
        unselectedLabelColor: Colors.white60,
      ),
    ),
    builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    home: const HomeScreen(),
  );
}
