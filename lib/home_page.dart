import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NECESARIA para FirebaseAuth.instance.signOut()
import 'routes.dart'; // NECESARIA para navegar al LoginPage

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    return Scaffold(
      appBar: AppBar(title: const Text("Menú Principal")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Este será la pantalla de "menú principal"',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            // Botón "Ir a Perfil" (de la imagen anterior)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
              child: const Text("Ir a Perfil"),
            ),

            // Espacio entre botones
            const SizedBox(height: 20),

            // Botón "Cerrar sesión" (de la imagen actual)
            ElevatedButton(
              onPressed: () async {
                // 1. Cerrar sesión en Firebase
                await _auth.signOut();

                Navigator.pushReplacementNamed(context, Routes.login);
              },
              child: const Text("Cerrar sesión"),
            ),
          ],
        ),
      ),
    );
  }
}
