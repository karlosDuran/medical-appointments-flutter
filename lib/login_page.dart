import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'routes.dart'; // Para las rutas nombradas

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Función auxiliar para mostrar mensajes (Snackbars)
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Lógica para crear una nueva cuenta (Botón: "Crear una cuenta nueva")
  Future<void> _createAccount() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        _showMessage("Cuenta creada con éxito. ¡Ya puedes ingresar!");
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'weak-password') {
          message = "La contraseña es muy débil.";
        } else if (e.code == 'email-already-in-use') {
          message = "El correo ya está en uso por otra cuenta.";
        } else {
          message = "Error al crear cuenta: ${e.message}";
        }
        _showMessage(message);
      }
    }
  }

  // Lógica para enviar el correo de restablecimiento (Botón: "Olvidó su contraseña")
  Future<void> _forgotPassword() async {
    if (emailController.text.trim().isEmpty) {
      _showMessage(
        "Por favor, ingresa tu correo para restablecer la contraseña.",
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
      _showMessage(
        "Se ha enviado un correo a ${emailController.text.trim()} para restablecer tu contraseña.",
      );
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = "No se encontró un usuario con ese correo.";
      } else {
        message = "Error al enviar correo: ${e.message}";
      }
      _showMessage(message);
    }
  }

  // Lógica para iniciar sesión (Botón: "Ingresar")
  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // NAVEGACIÓN EXITOSA: Utiliza la ruta nombrada HOME
        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.home);
        }
      } on FirebaseAuthException catch (e) {
        String message = "";
        if (e.code == 'user-not-found') {
          message = "No se encontró un usuario con ese correo.";
        } else if (e.code == 'wrong-password') {
          message = "Contraseña incorrecta.";
        } else {
          message = "Error: ${e.message}";
        }
        _showMessage(message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- CAMBIO AQUÍ: Añadir automáticamenteImplyLeading: false ---
      appBar: AppBar(
        title: const Text("Login de prueba"),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Campo para Correo Electrónico
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Correo electrónico / Usuario",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Por favor ingresa tu correo";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 2. Campo para Contraseña
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Contraseña",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Por favor ingresa tu contraseña";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 5. Botón para Iniciar Sesión
                ElevatedButton(
                  onPressed: _signIn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text("Ingresar"),
                ),

                const SizedBox(height: 16),

                // 3. Botón de "Olvidó su contraseña"
                TextButton(
                  onPressed: _forgotPassword,
                  child: const Text("¿Olvidó su contraseña?"),
                ),

                // 4. Botón de "Crear una cuenta nueva"
                TextButton(
                  onPressed: _createAccount,
                  child: const Text("Crear una cuenta nueva"),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
