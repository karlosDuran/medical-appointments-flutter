import 'package:flutter/material.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'login_page.dart';

class Routes {
  static const String root = '/'; // Añadimos la definición de la raíz
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // CAMBIO CLAVE: Manejar la ruta raíz '/'
      case root:
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
