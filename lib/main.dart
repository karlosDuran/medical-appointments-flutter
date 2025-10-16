import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // Contiene DefaultFirebaseOptions
import 'routes.dart'; // Importamos el generador de rutas

Future<void> main() async {
  // Asegura que los Widgets Binding estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Ejecuta la aplicación
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login de karlos',
      debugShowCheckedModeBanner: false, // Quita el banner de DEBUG
      // Determina la ruta inicial basándose en el estado de autenticación de Firebase
      initialRoute: FirebaseAuth.instance.currentUser != null
          ? Routes.home
          : Routes.login,

      // Generador de rutas que maneja las transiciones entre pantallas
      onGenerateRoute: Routes.generateRoute,

      // Nota: No se usa la propiedad 'home' ya que 'initialRoute' toma su lugar.
    );
  }
}
