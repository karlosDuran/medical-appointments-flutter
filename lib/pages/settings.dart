import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../routes.dart';
import '../services/firestore_service.dart';

const String _profileFileName = 'profile_picture.jpg';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  File? _profileImageFile;
  bool _isLoading = false;
  bool _isLoadingData = true;

  final TextEditingController _textEditController = TextEditingController();

  // Datos del usuario desde Firestore
  Map<String, dynamic>? _userData;
  String _name = "";
  String _phoneNumber = "";
  String _birthDate = "";
  DateTime? _selectedBirthDate;
  int? _age;
  bool? _isDoctor;

  // Campos para pacientes
  String _height = "";
  String _chronicCondition = "";

  // Campos para doctores
  List<String> _specialties = []; // Cambiado a lista
  Map<String, List<Map<String, String>>> _workSchedule = {};

  final Color primaryColor = const Color(0xFF007BFF);
  final Color accentColor = const Color(0xFF4A90E2);
  final Color detailColor = const Color(0xFF6C757D);

  final List<String> _daysOfWeek = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  final List<String> _availableSpecialties = [
    'Cardiología',
    'Pediatría',
    'Medicina General',
    'Dermatología',
    'Ginecología',
    'Neurología',
    'Traumatología',
    'Psiquiatría',
    'Oftalmología',
    'Otorrinolaringología',
  ];

  @override
  void initState() {
    super.initState();
    _loadLocalImage();
    _loadUserData();
  }

  @override
  void dispose() {
    _textEditController.dispose();
    super.dispose();
  }

  // Calcular edad
  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // --- CARGAR DATOS DE FIRESTORE ---
  Future<void> _loadUserData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    setState(() => _isLoadingData = true);

    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          _userData = data;
          _name = data['name'] ?? "";
          _phoneNumber = data['phone_number'] ?? "";
          _isDoctor = data['is_doctor'] ?? false;
          _age = data['age'];

          if (data['birth_date'] != null) {
            _selectedBirthDate = (data['birth_date'] as Timestamp).toDate();
            _birthDate = DateFormat('dd/MM/yyyy').format(_selectedBirthDate!);
          }

          if (_isDoctor == true) {
            // Cargar especialidades (puede ser string o lista)
            if (data['specialty'] != null) {
              if (data['specialty'] is List) {
                _specialties = List<String>.from(data['specialty']);
              } else {
                _specialties = [data['specialty'].toString()];
              }
            }

            if (data['work_schedule'] != null) {
              _workSchedule = Map<String, List<Map<String, String>>>.from(
                (data['work_schedule'] as Map).map(
                  (key, value) => MapEntry(
                    key.toString(),
                    List<Map<String, String>>.from(
                      (value as List).map(
                        (item) => Map<String, String>.from(item),
                      ),
                    ),
                  ),
                ),
              );
            }
          } else {
            _height = data['height'] ?? "";
            _chronicCondition = data['chronic_condition'] ?? "";
          }
        });
      }
    } catch (e) {
      _showMessage("Error al cargar datos: $e");
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  // --- FUNCIONES DE PERSISTENCIA DE IMAGEN ---

  Future<void> _loadLocalImage() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = File('${directory.path}/images/$_profileFileName');

    if (await path.exists()) {
      if (mounted) {
        setState(() {
          _profileImageFile = path;
        });
      }
    }
  }

  Future<void> _pickImageLocally() async {
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

  // --- FUNCIONES DE EDICIÓN ---

  Future<void> _updateFirestoreField(String field, dynamic value) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser.uid).update({
        field: value,
      });

      setState(() {
        switch (field) {
          case 'name':
            _name = value;
            break;
          case 'phone_number':
            _phoneNumber = value;
            break;
          case 'height':
            _height = value;
            break;
          case 'chronic_condition':
            _chronicCondition = value;
            break;
          case 'birth_date':
            _selectedBirthDate = (value as Timestamp).toDate();
            _birthDate = DateFormat('dd/MM/yyyy').format(_selectedBirthDate!);
            _age = _calculateAge(_selectedBirthDate!);
            break;
          case 'age':
            _age = value;
            break;
          case 'specialty':
            _specialties = List<String>.from(value);
            break;
          case 'work_schedule':
            _workSchedule = Map<String, List<Map<String, String>>>.from(
              (value as Map).map(
                (key, val) => MapEntry(
                  key.toString(),
                  List<Map<String, String>>.from(
                    (val as List).map((item) => Map<String, String>.from(item)),
                  ),
                ),
              ),
            );
            break;
        }
      });

      _showMessage("Campo actualizado correctamente.");
    } catch (e) {
      _showMessage("Error al actualizar: $e");
    }
  }

  // Diálogo para editar fecha de nacimiento
  Future<void> _showEditBirthDateDialog() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: primaryColor)),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final newAge = _calculateAge(picked);
      final currentUser = _auth.currentUser;

      if (currentUser != null) {
        try {
          // Actualizar ambos campos en Firestore
          await _firestore.collection('users').doc(currentUser.uid).update({
            'birth_date': Timestamp.fromDate(picked),
            'age': newAge,
          });

          setState(() {
            _selectedBirthDate = picked;
            _birthDate = DateFormat('dd/MM/yyyy').format(picked);
            _age = newAge;
          });

          _showMessage("Fecha de nacimiento actualizada.");
        } catch (e) {
          _showMessage("Error al actualizar: $e");
        }
      }
    }
  }

  // Diálogo para editar especialidades (múltiples)
  Future<void> _showEditSpecialtiesDialog() async {
    List<String> selectedSpecialties = List.from(_specialties);

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Editar Especialidades'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Selecciona una o más especialidades:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: _availableSpecialties.map((specialty) {
                        final isSelected = selectedSpecialties.contains(
                          specialty,
                        );
                        return CheckboxListTile(
                          title: Text(specialty),
                          value: isSelected,
                          activeColor: primaryColor,
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedSpecialties.add(specialty);
                              } else {
                                selectedSpecialties.remove(specialty);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                child: Text('Guardar', style: TextStyle(color: primaryColor)),
                onPressed: () {
                  if (selectedSpecialties.isNotEmpty) {
                    _updateFirestoreField('specialty', selectedSpecialties);
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Diálogo para agregar/editar horarios de trabajo
  Future<void> _showEditScheduleDialog() async {
    Map<String, List<Map<String, String>>> tempSchedule = Map.from(
      _workSchedule,
    );

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Editar Horarios'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Horario'),
                    onPressed: () async {
                      await _addWorkDayDialog(tempSchedule, setDialogState);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tip: Si pones la misma hora de inicio y fin, significa disponibilidad 24 horas',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: tempSchedule.entries.map((entry) {
                        return Card(
                          child: ExpansionTile(
                            title: Text(
                              entry.key,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            children: [
                              ...entry.value.asMap().entries.map((
                                intervalEntry,
                              ) {
                                final index = intervalEntry.key;
                                final interval = intervalEntry.value;

                                // Verificar si es 24 horas
                                final is24Hours =
                                    interval['start'] == interval['end'];

                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    is24Hours
                                        ? '24 horas (${interval['start']} - ${interval['end']})'
                                        : '${interval['start']} - ${interval['end']}',
                                    style: TextStyle(
                                      color: is24Hours
                                          ? primaryColor
                                          : Colors.black87,
                                      fontWeight: is24Hours
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setDialogState(() {
                                        tempSchedule[entry.key]!.removeAt(
                                          index,
                                        );
                                        if (tempSchedule[entry.key]!.isEmpty) {
                                          tempSchedule.remove(entry.key);
                                        }
                                      });
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                child: Text('Guardar', style: TextStyle(color: primaryColor)),
                onPressed: () {
                  _updateFirestoreField('work_schedule', tempSchedule);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Diálogo para agregar un día de trabajo
  Future<void> _addWorkDayDialog(
    Map<String, List<Map<String, String>>> schedule,
    StateSetter setDialogState,
  ) async {
    String? selectedDay;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setInnerDialogState) => AlertDialog(
          title: const Text('Agregar Horario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDay,
                  decoration: const InputDecoration(labelText: 'Día'),
                  items: _daysOfWeek
                      .map(
                        (day) => DropdownMenuItem(value: day, child: Text(day)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setInnerDialogState(() => selectedDay = value);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    startTime != null
                        ? 'Inicio: ${startTime!.format(context)}'
                        : 'Hora de inicio',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setInnerDialogState(() => startTime = time);
                    }
                  },
                ),
                ListTile(
                  title: Text(
                    endTime != null
                        ? 'Fin: ${endTime!.format(context)}'
                        : 'Hora de fin',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setInnerDialogState(() => endTime = time);
                    }
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Si la hora de inicio y fin son iguales, significa disponibilidad 24 horas',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedDay != null &&
                    startTime != null &&
                    endTime != null) {
                  setDialogState(() {
                    if (!schedule.containsKey(selectedDay)) {
                      schedule[selectedDay!] = [];
                    }
                    schedule[selectedDay]!.add({
                      'start':
                          '${startTime!.hour}:${startTime!.minute.toString().padLeft(2, '0')}',
                      'end':
                          '${endTime!.hour}:${endTime!.minute.toString().padLeft(2, '0')}',
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo de edición de texto
  Future<void> _showEditDialog(
    BuildContext context,
    String title,
    String currentValue,
    String fieldName, {
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
                _updateFirestoreField(
                  fieldName,
                  _textEditController.text.trim(),
                );
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildUserInfoCard(
    String title,
    String value, {
    bool editable = false,
    String? fieldName,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onEditCustom,
  }) {
    final bool isMissing =
        value.isEmpty || value == "No Disponible" || value == "No especificado";

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
              if (editable)
                IconButton(
                  icon: Icon(Icons.edit, size: 20, color: primaryColor),
                  onPressed:
                      onEditCustom ??
                      () => _showEditDialog(
                        context,
                        "Editar $title",
                        isMissing ? "" : value,
                        fieldName!,
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

    final String userEmail = currentUser.email ?? "No Disponible";

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading || _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Foto de perfil
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
                      _name.isEmpty ? userEmail : _name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Información Personal
                  Text(
                    "Información Personal",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const Divider(color: Colors.grey, height: 20),

                  _buildUserInfoCard(
                    "Nombre Completo",
                    _name,
                    editable: true,
                    fieldName: 'name',
                  ),

                  _buildUserInfoCard("Email", userEmail),

                  if (_birthDate.isNotEmpty)
                    _buildUserInfoCard(
                      "Fecha de Nacimiento",
                      _birthDate,
                      editable: true,
                      onEditCustom: _showEditBirthDateDialog,
                    ),

                  if (_age != null) _buildUserInfoCard("Edad", "$_age años"),

                  _buildUserInfoCard(
                    "Número de Teléfono",
                    _phoneNumber,
                    editable: true,
                    fieldName: 'phone_number',
                    keyboardType: TextInputType.phone,
                  ),

                  // Campos específicos para doctores
                  if (_isDoctor == true) ...[
                    const SizedBox(height: 20),
                    Text(
                      "Información Profesional",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const Divider(color: Colors.grey, height: 20),

                    // Especialidades (múltiples)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.1),
                            blurRadius: 5,
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Especialidades",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: detailColor,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: primaryColor,
                                ),
                                onPressed: _showEditSpecialtiesDialog,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (_specialties.isEmpty)
                            const Text(
                              'Sin especialidades',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _specialties.map((spec) {
                                return Chip(
                                  label: Text(spec),
                                  backgroundColor: primaryColor.withOpacity(
                                    0.1,
                                  ),
                                  labelStyle: TextStyle(color: primaryColor),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),

                    // Horarios de trabajo con botón de editar
                    Container(
                      padding: const EdgeInsets.all(16),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Horarios de Trabajo",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: detailColor,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: primaryColor,
                                ),
                                onPressed: _showEditScheduleDialog,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_workSchedule.isEmpty)
                            const Text(
                              'No hay horarios configurados',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            ..._workSchedule.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    ...entry.value.map((interval) {
                                      final is24Hours =
                                          interval['start'] == interval['end'];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          left: 16,
                                          top: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              is24Hours
                                                  ? '24 horas'
                                                  : '${interval['start']} - ${interval['end']}',
                                              style: TextStyle(
                                                color: is24Hours
                                                    ? primaryColor
                                                    : Colors.black87,
                                                fontWeight: is24Hours
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                            if (is24Hours) ...[
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: primaryColor,
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],

                  // Campos específicos para pacientes
                  if (_isDoctor == false) ...[
                    const SizedBox(height: 20),
                    Text(
                      "Información Médica",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const Divider(color: Colors.grey, height: 20),

                    _buildUserInfoCard(
                      "Altura (cm)",
                      _height,
                      editable: true,
                      fieldName: 'height',
                      keyboardType: TextInputType.number,
                    ),

                    _buildUserInfoCard(
                      "Padecimiento Crónico",
                      _chronicCondition.isEmpty ? "Ninguno" : _chronicCondition,
                      editable: true,
                      fieldName: 'chronic_condition',
                    ),
                  ],

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
