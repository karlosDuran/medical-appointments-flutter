import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // NECESARIO: Para obtener la ruta del directorio
import 'routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  // CAMBIO: El archivo local ahora representa la imagen guardada permanentemente.
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

  // --- Constante para la imagen de perfil ---
  static const String _profileFileName = 'profile_picture.jpg';

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadLocalImage(); // Carga la imagen guardada al iniciar
  }

  // --- FUNCIONES DE PERSISTENCIA DE IMAGEN ---

  Future<File> _getProfileImagePath() async {
    final directory = await getApplicationDocumentsDirectory();
    // Creamos la subcarpeta 'images'
    final imageDirectory = Directory('${directory.path}/images');
    if (!await imageDirectory.exists()) {
      await imageDirectory.create(recursive: true);
    }
    return File('${imageDirectory.path}/$_profileFileName');
  }

  Future<void> _loadLocalImage() async {
    if (_currentUser == null) return;
    final path = await _getProfileImagePath();

    if (await path.exists()) {
      setState(() {
        _profileImageFile = path;
      });
    }
  }

  Future<void> _pickImageLocally() async {
    if (_currentUser == null) {
      _showMessage("Debes estar autenticado para cambiar la foto.");
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newImagePath = await _getProfileImagePath();
      final originalFile = File(image.path);

      // COPIA el archivo seleccionado a la ruta permanente (images/profile_picture.jpg)
      final savedFile = await originalFile.copy(newImagePath.path);

      setState(() {
        _profileImageFile = savedFile;
        _showMessage("Imagen de perfil guardada localmente.");
      });

      // NOTA: En una app real, aquí también se llamaría a _currentUser!.updatePhotoURL(newImagePath.path);
      // para actualizar la referencia en Firebase Auth, pero eso requiere Storage.
    } catch (e) {
      _showMessage("Error al guardar imagen localmente: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Funciones de Edición (Omitidas para brevedad, no hay cambios en la lógica) ---

  // Lógica de _updateDisplayName
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

  // Lógica de _updateField
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

  // Lógica de _showEditDialog
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

  // Lógica de _showMessage
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Lógica de _buildUserInfoCard
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

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Mi Perfil",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
                          backgroundImage: _profileImageFile != null
                              ? FileImage(_profileImageFile!)
                                    as ImageProvider<Object>?
                              : null,
                          child: _profileImageFile == null
                              ? const Icon(
                                  Icons.person,
                                  size: 70,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        // Botón para cambiar la foto de perfil
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap:
                                _pickImageLocally, // USA LA FUNCIÓN DE GUARDADO PERSISTENTE
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
                    "Información de la Cuenta (Colección Usuarios)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const Divider(color: Colors.grey, height: 20),

                  // 1. Campo Nombre
                  _buildUserInfoCard(
                    "Nombre Completo (Campo 'nombre')",
                    userName,
                    editable: true,
                    onEdit: _updateDisplayName,
                  ),

                  // 2. Campo Email
                  _buildUserInfoCard("Email (Campo 'email')", userEmail),

                  // 3. ID de Usuario
                  _buildUserInfoCard("ID de Usuario (Clave Documento)", userId),

                  // 4. Campo Teléfono
                  _buildUserInfoCard(
                    "Teléfono (Campo 'número_teléfono')",
                    _phoneNumber,
                    editable: true,
                    onEdit: (newValue) => _updateField('phoneNumber', newValue),
                    keyboardType: TextInputType.phone,
                  ),

                  // 5. Historial Médico
                  _buildUserInfoCard(
                    "Historial Médico (Campo 'historial_médico')",
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
