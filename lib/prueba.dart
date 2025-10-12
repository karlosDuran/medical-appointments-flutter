import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Importa el archivo principal para poder navegar de vuelta al LoginPage
import 'main.dart';

class PruebaPage extends StatelessWidget {
  // Constructor corregido: se elimina 'const' porque el widget contiene la instancia de FirebaseAuth.
  PruebaPage({super.key});

  // Instancia de FirebaseAuth para cerrar la sesión
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Función para cerrar la sesión
  Future<void> _signOut(BuildContext context) async {
    try {
      await _auth.signOut();

      // Navega de vuelta a la página de Login y elimina todas las rutas anteriores
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al cerrar sesión: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el correo del usuario actual
    final userEmail = _auth.currentUser?.email ?? "Usuario";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pantalla de Prueba"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Mensaje de bienvenida
            Text(
              "¡Bienvenido, $userEmail!",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Has iniciado sesión correctamente.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),

            // Botón para Cerrar Sesión
            ElevatedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout),
              label: const Text("Cerrar Sesión"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
