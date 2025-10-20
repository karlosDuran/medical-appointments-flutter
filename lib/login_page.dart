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

  // Definición de colores para el tema médico
  final Color primaryColor = const Color(0xFF007BFF); // Azul principal
  final Color accentColor = const Color(0xFF4A90E2); // Azul más claro
  final Color backgroundColor = Colors.white;

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

  // Widget para el encabezado con la forma de onda
  Widget _buildWaveHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250, // Altura del encabezado
      decoration: BoxDecoration(
        color: primaryColor,
        // Usamos un clipPath para simular la forma de onda
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        gradient: LinearGradient(
          colors: [primaryColor, accentColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de ejemplo para la app médica
            Icon(Icons.health_and_safety, size: 70, color: Colors.white),
            SizedBox(height: 10),
            Text(
              "Bienvenido de nuevo",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      // No usamos AppBar, ya que el encabezado es personalizado
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado de la Onda
            _buildWaveHeader(context),

            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(
                      height: 10,
                    ), // Espacio después del encabezado
                    // Título del formulario
                    const Text(
                      "Iniciar Sesión",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1. Campo para Correo Electrónico
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Correo electrónico / Usuario",
                        prefixIcon: Icon(Icons.person, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
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
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: Icon(Icons.lock, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor ingresa tu contraseña";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // 5. Botón para Iniciar Sesión (Relleno)
                    ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        "Ingresar",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 3. Botón de "Olvidó su contraseña" (Texto simple)
                    TextButton(
                      onPressed: _forgotPassword,
                      child: Text(
                        "¿Olvidó su contraseña?",
                        style: TextStyle(color: accentColor),
                      ),
                    ),

                    // 4. Botón de "Crear una cuenta nueva" (Texto simple)
                    TextButton(
                      onPressed: _createAccount,
                      child: Text(
                        "Crear una cuenta nueva",
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
