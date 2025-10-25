import 'package:flutter/material.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'main_screen.dart';
import 'pages/settings.dart';
import 'pages/messages.dart';
import 'pages/schedule_appointment_page.dart';
import 'pages/schedule.dart';

// Placeholder para la clase SchedulePage si se usa directamente, aunque usaremos ScheduleView

class Routes {
  static const String root = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile =
      '/profile'; // Usada internamente para la pestaña de Settings
  static const String messages = '/messages';
  static const String schedule = '/schedule';
  static const String scheduleAppointment = '/scheduleAppointment';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case root:
      case home:
        // La ruta principal siempre carga el shell de navegación.
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case profile:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case messages:
        return MaterialPageRoute(builder: (_) => const MessagesPage());
      case schedule:
        return MaterialPageRoute(builder: (_) => const SchedulePage());

      case scheduleAppointment:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => ScheduleAppointmentPage(appointmentType: args),
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              const Center(child: Text('Error: Tipo de cita no especificado.')),
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
