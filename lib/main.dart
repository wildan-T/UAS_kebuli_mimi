import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kebuli_mimi/services/auth_service.dart';
import 'package:kebuli_mimi/services/order_service.dart';
import 'package:kebuli_mimi/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kebuli_mimi/models/cart_model.dart';
import 'package:kebuli_mimi/screens/auth/login_screen.dart';
import 'package:kebuli_mimi/screens/auth/register_screen.dart';
import 'package:kebuli_mimi/screens/splash_screen.dart';
import 'package:kebuli_mimi/screens/admin/admin_home.dart';
import 'package:kebuli_mimi/screens/user/home_screen.dart';
import 'package:kebuli_mimi/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Muat environment variables dari file .env
  await dotenv.load(fileName: ".env");

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Cart()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => OrderService()),
        Provider(create: (_) => UserService()),
        // Add other providers here
      ],
      child: MaterialApp(
        title: 'Kebuli Mimi',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/admin': (context) => const AdminHomeScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
