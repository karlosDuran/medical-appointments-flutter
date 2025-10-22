import 'package:appointment/pages/messages.dart';
import 'package:appointment/pages/schedule_appointment_page.dart';
import 'package:appointment/pages/settings.dart';
import 'package:flutter/material.dart';

import 'login_page.dart';
import 'main_screen.dart';

// Placeholder para la página de Citas (Schedule) - ¡ELIMINADO!
// Ahora usaremos el widget real ScheduleAppointmentPage

class Routes {
  static const String root = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile =
      '/profile'; // Mantenemos la ruta para Profile (aunque ahora es Settings)
  static const String messages = '/messages'; // Nueva ruta para Mensajes
  static const String schedule = '/schedule'; // Nueva ruta para Citas

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case root:
      case home:
        // La ruta principal siempre carga el shell de navegación.
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case profile:
        // Pestaña de Configuración/Perfil
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case messages:
        // Pestaña de Mensajes
        return MaterialPageRoute(builder: (_) => const MessagesPage());
      case schedule:
        // CAMBIO CLAVE: Carga la página de agendar citas
        return MaterialPageRoute(
          builder: (_) => const ScheduleAppointmentPage(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
