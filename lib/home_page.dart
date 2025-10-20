import 'dart:io'; // Necesario para File
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importar FirebaseAuth para obtener el usuario
import 'package:path_provider/path_provider.dart'; // NECESARIO: Para obtener la ruta de la imagen
import 'routes.dart'; // NECESARIA para navegar a otras rutas nombradas

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Definición de colores, alineados con el tema azul de la LoginPage
  final Color primaryColor = const Color(0xFF007BFF); // Azul principal
  final Color accentColor = const Color(0xFF4A90E2); // Azul más claro

  // Constante para la imagen de perfil
  static const String _profileFileName = 'profile_picture.jpg';

  // Variables de estado
  User? _currentUser;
  File?
  _localProfileImageFile; // CAMBIO: Usaremos esta variable para la imagen local

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadLocalImage(); // Carga la imagen al iniciar
  }

  // Función para obtener la ruta y cargar la imagen local guardada
  Future<void> _loadLocalImage() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = File('${directory.path}/images/$_profileFileName');

    if (await path.exists()) {
      setState(() {
        _localProfileImageFile = path;
      });
    } else {
      setState(() {
        _localProfileImageFile = null;
      });
    }
  }

  // Función para navegar a Perfil y recargar datos al regresar
  void _navigateToProfilePage() async {
    // Espera hasta que la ProfilePage se cierre (pop).
    await Navigator.pushNamed(context, Routes.profile);

    // Cuando regrese, recarga los datos del usuario y la imagen local
    await _currentUser?.reload();
    await _loadLocalImage(); // CAMBIO: Recargar la imagen local

    setState(() {
      _currentUser = FirebaseAuth.instance.currentUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el widget de la imagen para el CircleAvatar
    final ImageProvider<Object>? backgroundImage =
        (_localProfileImageFile != null)
        ? FileImage(_localProfileImageFile!) as ImageProvider<Object>?
        : null; // Si no hay archivo local, es nulo

    // Contenido dentro del CircleAvatar
    final Widget iconChild = (_localProfileImageFile != null)
        ? const SizedBox.shrink() // Si hay imagen local, no hay hijo
        : const Icon(
            Icons.person,
            color: Colors.white,
            size: 24,
          ); // Si no hay imagen, mostramos el icono

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Menú Principal",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        // --- Quitar el botón de retroceso ---
        automaticallyImplyLeading: false,
        // --- Botón de Perfil con foto en Actions ---
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: accentColor,
              backgroundImage: backgroundImage, // Usa la imagen local
              child: iconChild, // Muestra el icono si no hay imagen
            ),
            tooltip: 'Ir a Perfil',
            onPressed:
                _navigateToProfilePage, // Llama a la función que navega y recarga
          ),
          const SizedBox(width: 8), // Espacio al final
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Icono grande para la pantalla principal
            Icon(Icons.healing, size: 80, color: primaryColor),
            const SizedBox(height: 20),

            const Text(
              '¡Bienvenido a tu aplicación médica!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 10),

            // Texto descriptivo
            Text(
              'Aquí encontrarás tus citas y tu información principal.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
