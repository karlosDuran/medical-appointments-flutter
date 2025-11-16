import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../routes.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();
  final Color primaryColor = const Color(0xFF007BFF);
  final Color accentColor = const Color(0xFF4A90E2);

  // Controladores comunes
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  // Controladores para pacientes
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _chronicConditionController =
      TextEditingController();

  // Variables
  bool? _isDoctor;
  DateTime? _selectedBirthDate;
  String? _selectedSpecialty;

  // Lista de especialidades
  final List<String> _specialties = [
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

  // Horarios del doctor (día -> lista de intervalos)
  Map<String, List<Map<String, TimeOfDay>>> _workSchedule = {};

  final List<String> _daysOfWeek = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _heightController.dispose();
    _chronicConditionController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
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
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _addWorkDay() async {
    String? selectedDay;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar horario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDay,
                  decoration: const InputDecoration(labelText: 'Día'),
                  items: _daysOfWeek
                      .where((day) => !_workSchedule.containsKey(day))
                      .map(
                        (day) => DropdownMenuItem(value: day, child: Text(day)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedDay = value);
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
                      setDialogState(() => startTime = time);
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
                      setDialogState(() => endTime = time);
                    }
                  },
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
                  setState(() {
                    if (!_workSchedule.containsKey(selectedDay)) {
                      _workSchedule[selectedDay!] = [];
                    }
                    _workSchedule[selectedDay]!.add({
                      'start': startTime!,
                      'end': endTime!,
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

  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Usuario no autenticado');

        final age = _calculateAge(_selectedBirthDate!);

        Map<String, dynamic> userData = {
          'name': _fullNameController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'birth_date': Timestamp.fromDate(_selectedBirthDate!),
          'age': age,
          'is_doctor': _isDoctor,
          'created_at': FieldValue.serverTimestamp(),
        };

        if (_isDoctor == true) {
          // Convertir horarios a formato serializable
          Map<String, List<Map<String, String>>> scheduleData = {};
          _workSchedule.forEach((day, intervals) {
            scheduleData[day] = intervals
                .map(
                  (interval) => {
                    'start':
                        '${interval['start']!.hour}:${interval['start']!.minute}',
                    'end':
                        '${interval['end']!.hour}:${interval['end']!.minute}',
                  },
                )
                .toList();
          });

          userData.addAll({
            'specialty': [_selectedSpecialty], // Ahora es una lista
            'work_schedule': scheduleData,
          });
        } else {
          userData.addAll({
            'height': _heightController.text.trim(),
            'chronic_condition': _chronicConditionController.text.trim(),
          });
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(userData);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil completado exitosamente')),
        );
        Navigator.pushReplacementNamed(context, Routes.home);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Completar Perfil'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pregunta: ¿Eres doctor?
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¿Eres doctor?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Sí'),
                              value: true,
                              groupValue: _isDoctor,
                              onChanged: (value) {
                                setState(() => _isDoctor = value);
                              },
                              activeColor: primaryColor,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('No'),
                              value: false,
                              groupValue: _isDoctor,
                              onChanged: (value) {
                                setState(() => _isDoctor = value);
                              },
                              activeColor: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Campos comunes
              if (_isDoctor != null) ...[
                // Nombre completo
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),

                // Fecha de nacimiento
                InkWell(
                  onTap: _selectBirthDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Fecha de nacimiento',
                      prefixIcon: Icon(
                        Icons.calendar_today,
                        color: primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _selectedBirthDate != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedBirthDate!)
                          : 'Selecciona una fecha',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Número de teléfono
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Número de teléfono',
                    prefixIcon: Icon(Icons.phone, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 20),

                // Campos específicos para doctores
                if (_isDoctor == true) ...[
                  // Especialidad
                  DropdownButtonFormField<String>(
                    value: _selectedSpecialty,
                    decoration: InputDecoration(
                      labelText: 'Especialidad',
                      prefixIcon: Icon(
                        Icons.medical_services,
                        color: primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _specialties
                        .map(
                          (spec) =>
                              DropdownMenuItem(value: spec, child: Text(spec)),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedSpecialty = value);
                    },
                    validator: (value) =>
                        value == null ? 'Selecciona una especialidad' : null,
                  ),
                  const SizedBox(height: 20),

                  // Horarios de trabajo
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Horarios de trabajo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.add_circle,
                                  color: primaryColor,
                                ),
                                onPressed: _addWorkDay,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_workSchedule.isEmpty)
                            const Text(
                              'No hay horarios agregados',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ..._workSchedule.entries.map((entry) {
                              return Column(
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
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        top: 4,
                                      ),
                                      child: Text(
                                        '${interval['start']!.format(context)} - ${interval['end']!.format(context)}',
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                ],
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ],

                // Campos específicos para pacientes
                if (_isDoctor == false) ...[
                  // Altura
                  TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Altura (cm)',
                      prefixIcon: Icon(Icons.height, color: primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Campo requerido'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Padecimiento crónico
                  TextFormField(
                    controller: _chronicConditionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Padecimiento crónico (opcional)',
                      prefixIcon: Icon(Icons.healing, color: primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Ej: Diabetes, Hipertensión, Ninguno',
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // Botón guardar
                ElevatedButton(
                  onPressed: _saveUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Guardar y Continuar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
