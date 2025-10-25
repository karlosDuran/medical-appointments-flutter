import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../routes.dart';
import '../services/firestore_service.dart';

// Constante para la imagen de perfil
const String _profileFileName = 'profile_picture.jpg';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService =
      FirestoreService(); // Usar instancia

  // Variables de estado
  File? _profileImageFile;
  bool _isLoading = false;

  final TextEditingController _textEditController = TextEditingController();

  // Datos del usuario obtenidos del Stream
  Map<String, dynamic>? _userData;

  // Definición de colores
  final Color primaryColor = const Color(0xFF007BFF);
  final Color accentColor = const Color(0xFF4A90E2);
  final Color detailColor = const Color(0xFF6C757D);

  @override
  void initState() {
    super.initState();
    _loadLocalImage();
  }

  // --- LÓGICA DE DATOS Y FIREBASE ---

  // Función que se encarga de crear el documento si no existe, y luego lo lee.
  // Esta lógica se ejecuta en el primer build del StreamBuilder.
  Future<void> _createInitialDocumentIfMissing(User currentUser) async {
    await _firestoreService.createUserProfile(
      currentUser.uid,
      currentUser.email ?? '',
    );
  }

  Future<void> _updateDisplayName(String newName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || newName.trim().isEmpty) return;
    try {
      await currentUser.updateDisplayName(newName);
      // También actualizamos el nombre en Firestore para consistencia
      await _firestoreService.updateUserField(currentUser.uid, 'name', newName);

      _showMessage("Nombre de usuario actualizado.");
    } catch (e) {
      _showMessage("Error al actualizar el nombre: $e");
    }
  }

  void _updateField(String field, String newValue) {
    final currentUser = _auth.currentUser;
    if (currentUser == null || newValue.trim().isEmpty) {
      _showMessage("El campo no puede estar vacío.");
      return;
    }

    // Campo de historial médico es mapeado a 'historial_medico' en Firestore
    final firestoreField = field == 'medicalHistory'
        ? 'historial_medico'
        : field;

    _firestoreService
        .updateUserField(currentUser.uid, firestoreField, newValue)
        .then((_) {
          _showMessage("Campo actualizado con éxito.");
        })
        .catchError((e) {
          _showMessage("Error al guardar: $e");
        });
  }

  // --- LÓGICA DE IMAGEN LOCAL ---

  Future<void> _loadLocalImage() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = File('${directory.path}/images/$_profileFileName');

    if (await path.exists()) {
      if (mounted) {
        setState(() {
          _profileImageFile = path;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _profileImageFile = null;
        });
      }
    }
  }

  Future<void> _pickImageLocally() async {
    // ... (lógica de selección y guardado de imagen omitida, no cambió) ...
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final newPath = '${imagesDir.path}/$_profileFileName';
      final savedFile = await File(image.path).copy(newPath);

      if (mounted) {
        setState(() {
          _profileImageFile = savedFile;
          _showMessage("Imagen de perfil guardada localmente.");
        });
      }
    } catch (e) {
      _showMessage("Error al guardar imagen: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI Y UTILERIAS ---

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
              onPressed: () => Navigator.of(dialogContext).pop(),
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

  Widget _buildUserInfoCard(
    String title,
    String value, {
    bool editable = false,
    Function(String)? onEdit,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final bool isMissing =
        value.isEmpty ||
        value == "No especificado" ||
        value == "Pendiente de cargar" ||
        value == "Nombre No Configurado" ||
        value == "ID No Disponible"; // Añadimos chequeos para strings vacías

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 5),
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
                    "Editar ${title}",
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
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("Error: No hay usuario autenticado."));
    }

    // --- Usamos StreamBuilder para leer datos del usuario en tiempo real ---
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _firestoreService.getUserDataStream(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Verifica si el documento de usuario existe. Si no, lo crea (primer inicio de sesión después del registro).
        if (!snapshot.hasData || snapshot.data == null) {
          _createInitialDocumentIfMissing(currentUser);
          return const Center(child: Text("Creando perfil inicial..."));
        }

        _userData = snapshot.data;

        final String userName =
            _userData?['name'] ?? currentUser.displayName ?? '';
        final String userEmail = currentUser.email ?? 'No Disponible';
        final String userId = currentUser.uid;
        final String phoneNumber =
            _userData?['phone_number'] ?? 'No especificado';
        final String medicalHistory =
            _userData?['historial_medico'] ?? 'Pendiente de cargar';

        final ImageProvider<Object>? backgroundImage =
            (_profileImageFile != null)
            ? FileImage(_profileImageFile!) as ImageProvider<Object>?
            : null;
        final Widget iconChild = (_profileImageFile != null)
            ? const SizedBox.shrink()
            : const Icon(Icons.person_pin, size: 70, color: Colors.white);

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
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
                      _buildUserInfoCard("Email", userEmail),

                      // 3. ID de Usuario (No editable)
                      _buildUserInfoCard("ID de Usuario", userId),

                      // 4. Campo Teléfono
                      _buildUserInfoCard(
                        "Teléfono",
                        phoneNumber,
                        editable: true,
                        onEdit: (newValue) =>
                            _updateField('phone_number', newValue),
                        keyboardType: TextInputType.phone,
                      ),

                      // 5. Historial Médico
                      _buildUserInfoCard(
                        "Historial Médico",
                        medicalHistory,
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
      },
    );
  }
}
