import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // <--- NUEVA IMPORTACIÓN
import 'firebase_options.dart';
import 'routes.dart';

Future<void> main() async {
  // Asegura que los Widgets Binding estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- INICIALIZACIÓN DE APP CHECK CORREGIDA ---
  await FirebaseAppCheck.instance.activate(
    // Usa DebugProvider en desarrollo para eliminar la advertencia
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
    // ELIMINADA: La propiedad webProvider.debug no existe.
    // Usar la sintaxis correcta para Android/Apple es suficiente.
  );
  // ------------------------------------

  // Ejecuta la aplicación
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor Appointment App',
      debugShowCheckedModeBanner: false,

      initialRoute: FirebaseAuth.instance.currentUser != null
          ? Routes.home
          : Routes.login,

      onGenerateRoute: Routes.generateRoute,
    );
  }
}
