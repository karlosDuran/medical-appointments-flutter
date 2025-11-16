import 'package:appointment/create_secion.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'main_screen.dart';
import 'pages/settings.dart';
import 'pages/messages.dart';
import 'pages/schedule_appointment_page.dart';
import 'pages/schedule.dart';
import 'pages/edit_appointment_page.dart';
import 'pages/create_user.dart';

class Routes {
  static const String root = '/';
  static const String login = '/login';
  static const String createSession = '/createSession';
  static const String createUser = '/createUser';
  static const String home = '/home';
  static const String profile =
      '/profile'; // Usada internamente para la pestaña de Settings
  static const String messages = '/messages';
  static const String schedule = '/schedule';
  static const String scheduleAppointment = '/scheduleAppointment';
  static const String editAppointment = '/editAppointment';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case root:
      case home:
        // La ruta principal siempre carga el shell de navegación.
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case createSession:
        return MaterialPageRoute(builder: (_) => const CreateSessionPage());
      case createUser:
        return MaterialPageRoute(builder: (_) => const CreateUserPage());
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

      case editAppointment:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => EditAppointmentPage(docId: args),
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              const Center(child: Text('Error: ID de cita no especificado.')),
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
