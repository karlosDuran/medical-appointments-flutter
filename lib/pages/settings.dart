import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../routes.dart';

// Constante para la imagen de perfil (movida aquí)
const String _profileFileName = 'profile_picture.jpg';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  // Variables de estado
  File? _profileImageFile;
  bool _isLoading = false;

  // Controladores y variables de estado para campos editables:
  final TextEditingController _textEditController = TextEditingController();
  String _phoneNumber = "";
  String _medicalHistory = "Pendiente de cargar";

  // Definición de colores
  final Color primaryColor = const Color(0xFF007BFF);
  final Color accentColor = const Color(0xFF4A90E2);
  final Color detailColor = const Color(0xFF6C757D);

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadLocalImage();
  }

  // --- Lógica de la imagen ---

  Future<void> _loadLocalImage() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = File('${directory.path}/images/$_profileFileName');

    if (await path.exists()) {
      setState(() {
        _profileImageFile = path;
      });
    } else {
      setState(() {
        _profileImageFile = null;
      });
    }
  }

  Future<void> _pickImageLocally() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Copiar la imagen seleccionada al directorio local permanente
      final newPath = '${imagesDir.path}/$_profileFileName';
      final savedFile = await File(image.path).copy(newPath);

      setState(() {
        _profileImageFile = savedFile;
        _showMessage("Imagen de perfil guardada localmente.");
      });
    } catch (e) {
      _showMessage("Error al guardar imagen: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Lógica de Edición y UI ---

  Future<void> _updateDisplayName(String newName) async {
    if (_currentUser == null || newName.trim().isEmpty) return;
    try {
      await _currentUser!.updateDisplayName(newName);
      setState(() {
        _currentUser = _auth.currentUser;
      });
      _showMessage("Nombre de usuario actualizado.");
    } catch (e) {
      _showMessage("Error al actualizar el nombre: $e");
    }
  }

  void _updateField(String field, String newValue) {
    if (newValue.trim().isEmpty) {
      _showMessage("El campo no puede estar vacío.");
      return;
    }

    setState(() {
      if (field == 'phoneNumber') {
        _phoneNumber = newValue;
        _showMessage("Número de teléfono actualizado.");
      } else if (field == 'medicalHistory') {
        _medicalHistory = newValue;
        _showMessage("Historial médico actualizado.");
      }
    });
  }

  Future<void> _showEditDialog(
    BuildContext context,
    String title,
    String currentValue,
    Function(String) onSave, {
    TextInputType keyboardType = TextInputType.text,
  }) async {
    _textEditController.text = currentValue;

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: _textEditController,
            decoration: const InputDecoration(
              hintText: "Ingresa el nuevo valor",
            ),
            autofocus: true,
            keyboardType: keyboardType,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Guardar', style: TextStyle(color: primaryColor)),
              onPressed: () {
                onSave(_textEditController.text);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Función auxiliar para mostrar mensajes (Snackbars)
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Función para construir la tarjeta de información del usuario
  Widget _buildUserInfoCard(
    String title,
    String value, {
    bool editable = false,
    Function(String)? onEdit,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final bool isMissing =
        value.isEmpty ||
        value == "Nombre No Configurado" ||
        value == "No Disponible" ||
        value == "Pendiente de cargar" ||
        value == "No especificado";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: detailColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isMissing ? "Completar" : value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isMissing ? Colors.grey.shade600 : Colors.black87,
                    fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
              if (editable && onEdit != null)
                IconButton(
                  icon: Icon(Icons.edit, size: 20, color: primaryColor),
                  onPressed: () => _showEditDialog(
                    context,
                    "Editar ${title.split('(')[0].trim()}",
                    isMissing ? "" : value,
                    onEdit,
                    keyboardType: keyboardType,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userName = _currentUser?.displayName ?? "";
    final String userEmail = _currentUser?.email ?? "No Disponible";
    final String userId = _currentUser?.uid ?? "ID No Disponible";

    // Obtenemos el widget de la imagen para el CircleAvatar
    final ImageProvider<Object>? backgroundImage = (_profileImageFile != null)
        ? FileImage(_profileImageFile!) as ImageProvider<Object>?
        : null; // Si no hay archivo local, es nulo

    // Contenido dentro del CircleAvatar
    final Widget iconChild = (_profileImageFile != null)
        ? const SizedBox.shrink() // Si hay imagen local, no hay hijo
        : const Icon(
            Icons.person_pin,
            size: 70,
            color: Colors.white,
          ); // Si no hay imagen, mostramos el icono

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      // Nota: El AppBar se gestiona desde MainScreen
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sección de la foto de perfil (circular)
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: accentColor.withOpacity(0.5),
                          backgroundImage: backgroundImage,
                          child: iconChild,
                        ),
                        // Botón para cambiar la foto de perfil
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImageLocally,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: primaryColor,
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      userName.isEmpty ? userEmail : userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Título de la sección de información
                  Text(
                    "Información de la Cuenta",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const Divider(color: Colors.grey, height: 20),

                  // 1. Campo Nombre
                  _buildUserInfoCard(
                    "Nombre Completo",
                    userName,
                    editable: true,
                    onEdit: _updateDisplayName,
                  ),

                  // 2. Campo Email (No editable)
                  _buildUserInfoCard("Email (No editable)", userEmail),

                  // 3. ID de Usuario (No editable)
                  _buildUserInfoCard("ID de Usuario", userId),

                  // 4. Campo Teléfono
                  _buildUserInfoCard(
                    "Teléfono",
                    _phoneNumber,
                    editable: true,
                    onEdit: (newValue) => _updateField('phoneNumber', newValue),
                    keyboardType: TextInputType.phone,
                  ),

                  // 5. Historial Médico
                  _buildUserInfoCard(
                    "Historial Médico",
                    _medicalHistory,
                    editable: true,
                    onEdit: (newValue) =>
                        _updateField('medicalHistory', newValue),
                  ),

                  const SizedBox(height: 40),

                  // Botón de Cerrar Sesión
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      "Cerrar Sesión",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    onPressed: () async {
                      await _auth.signOut();
                      // Navega al login y limpia todas las rutas anteriores
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        Routes.login,
                        (Route<dynamic> route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
