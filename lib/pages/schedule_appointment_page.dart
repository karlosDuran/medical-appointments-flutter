import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // ← AGREGAR ESTA LÍNEA
import '../services/firestore_service.dart';
import '../services/schedule_service.dart'; // Agregar al inicio
import '../routes.dart';

class ScheduleAppointmentPage extends StatefulWidget {
  final String appointmentType;
  const ScheduleAppointmentPage({super.key, required this.appointmentType});

  @override
  State<ScheduleAppointmentPage> createState() =>
      _ScheduleAppointmentPageState();
}

class _ScheduleAppointmentPageState extends State<ScheduleAppointmentPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedDoctorId;
  String? _selectedDoctorName;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<TimeOfDay> _availableTimes = [];
  Map<String, dynamic>? _doctorWorkSchedule;
  final TextEditingController _reasonController = TextEditingController();

  final Color primaryColor = const Color(0xFF007BFF);

  bool _isLoadingTimes = false;
  bool _isSaving = false; // ← AGREGAR ESTA LÍNEA

  final ScheduleService _scheduleService =
      ScheduleService(); // Reemplazar _loadAvailableTimes()

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es'); // Inicializar localización en español
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // Parsear hora en formato flexible (acepta "0:00" o "00:00")
  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _getDayName(int weekday) {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return days[weekday - 1];
  }

  // Cargar los días que el doctor trabaja
  Future<void> _loadDoctorWorkDays() async {
    if (_selectedDoctorId == null) return;

    try {
      final doctorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedDoctorId)
          .get();

      if (!doctorDoc.exists) return;

      final workSchedule = doctorDoc.data()?['work_schedule'] as Map?;
      if (workSchedule == null) {
        _showMessage('Este doctor no tiene horarios configurados');
        return;
      }

      setState(() {
        _doctorWorkSchedule = Map<String, dynamic>.from(workSchedule);
      });
    } catch (e) {
      _showMessage('Error al cargar horarios: $e');
    }
  }

  // Verificar si un día es laborable para el doctor
  bool _isDoctorWorkingDay(DateTime date) {
    if (_doctorWorkSchedule == null) return false;
    final dayName = _getDayName(date.weekday);
    return _doctorWorkSchedule!.containsKey(dayName);
  }

  // Encontrar el próximo día laborable del doctor
  DateTime _findNextWorkingDay(DateTime startDate) {
    DateTime current = startDate;
    // Buscar hasta 60 días en el futuro
    for (int i = 0; i < 60; i++) {
      if (_isDoctorWorkingDay(current)) {
        return current;
      }
      current = current.add(const Duration(days: 1));
    }
    return startDate; // Fallback
  }

  // Obtener horarios disponibles del doctor para el día seleccionado
  Future<void> _loadAvailableTimes() async {
    if (_selectedDoctorId == null || _selectedDate == null) return;

    setState(() {
      _isLoadingTimes = true;
      _availableTimes = [];
      _selectedTime = null;
    });

    try {
      final availableTimeStrings = await _scheduleService
          .getAvailableTimesForDate(_selectedDoctorId!, _selectedDate!);

      final times = availableTimeStrings.map((timeStr) {
        final parts = timeStr.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList();

      setState(() {
        _availableTimes = times;
        _isLoadingTimes = false;
      });

      if (times.isEmpty && mounted) {
        _showMessage('No hay horarios disponibles para este día');
      }
    } catch (e) {
      setState(() => _isLoadingTimes = false);
      _showMessage('Error al cargar horarios: $e');
    }
  }

  Future<void> _selectDate() async {
    if (_selectedDoctorId == null) {
      _showMessage('Primero selecciona un doctor');
      return;
    }

    if (_doctorWorkSchedule == null) {
      _showMessage('Cargando horarios del doctor...');
      return;
    }

    // Encontrar el próximo día laborable del doctor
    final initialDate = _findNextWorkingDay(DateTime.now());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
      selectableDayPredicate: (DateTime date) {
        return _isDoctorWorkingDay(date);
      },
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadAvailableTimes();
    }
  }

  // Actualizar _saveAppointment() para marcar el horario como ocupado
  Future<void> _saveAppointment() async {
    if (_isSaving) return; // Evitar múltiples envíos

    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null) {
      setState(() => _isSaving = true); // ← AGREGAR

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isSaving = false);
        _showMessage("Error de autenticación. Por favor, reinicia la sesión.");
        return;
      }

      final finalDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final endTime = finalDateTime.add(const Duration(minutes: 30));

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Verificar una última vez que el horario sigue disponible
        print('🔍 Verificando disponibilidad final...');
        final availableTimes = await _scheduleService.getAvailableTimesForDate(
          _selectedDoctorId!,
          _selectedDate!,
        );

        final timeString =
            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

        if (!availableTimes.contains(timeString)) {
          if (mounted) Navigator.pop(context); // Cerrar loading
          _showMessage(
            'Este horario acaba de ser ocupado. Por favor, selecciona otro.',
          );

          // Recargar horarios disponibles
          await _loadAvailableTimes();
          return;
        }

        print('✅ Horario disponible, creando cita...');

        final appointmentData = {
          'patient_id': userId,
          'doctor_id': _selectedDoctorId,
          'specialist_name': _selectedDoctorName,
          'start_time': Timestamp.fromDate(finalDateTime),
          'end_time': Timestamp.fromDate(endTime),
          'reason': _reasonController.text.trim(),
          'type': widget.appointmentType,
          'status': 'agendada',
          'created_at': Timestamp.now(),
        };

        // Crear la cita en Firestore
        await FirestoreService().createAppointment(appointmentData);
        print('✅ Cita creada en appointments');

        // Marcar el horario como ocupado en schedules
        await _scheduleService.markTimeAsBooked(
          _selectedDoctorId!,
          finalDateTime,
        );
        print('✅ Horario marcado como ocupado en schedules');

        if (mounted) {
          setState(() => _isSaving = false);
          Navigator.pushReplacementNamed(context, Routes.home);
        }
      } catch (e) {
        print('❌ Error al guardar la cita: $e');
        if (mounted) {
          setState(() => _isSaving = false);
        }
        _showMessage("Error al guardar la cita: $e");
      }
    } else {
      _showMessage("Por favor, completa todos los campos.");
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Mostrar todas las especialidades en un diálogo
  void _showAllSpecialties(List<String> specialties) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Especialidades'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: specialties.map((specialty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.medical_services, color: primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(specialty)),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Agendar: ${widget.appointmentType}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Selecciona detalles de la cita',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Selector de Doctor desde Firestore
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('is_doctor', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'No hay doctores disponibles en este momento',
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final doctors = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Selecciona un Doctor',
                      prefixIcon: Icon(Icons.person_pin, color: primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    value: _selectedDoctorId,
                    hint: const Text('Selecciona un doctor'),
                    isExpanded: true,
                    items: doctors.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Sin nombre';
                      final specialties = data['specialty'];

                      List<String> specialtyList = [];
                      if (specialties is List) {
                        specialtyList = List<String>.from(specialties);
                      } else if (specialties is String) {
                        specialtyList = [specialties];
                      }

                      String specialtyText = '';
                      if (specialtyList.isNotEmpty) {
                        specialtyText = specialtyList.first;
                        if (specialtyList.length > 1) {
                          specialtyText += ' +${specialtyList.length - 1}';
                        }
                      }

                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Dr. $name',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (specialtyText.isNotEmpty)
                                    Text(
                                      specialtyText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                ],
                              ),
                            ),
                            if (specialtyList.length > 1)
                              IconButton(
                                icon: Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: primaryColor,
                                ),
                                onPressed: () =>
                                    _showAllSpecialties(specialtyList),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    selectedItemBuilder: (BuildContext context) {
                      return doctors.map<Widget>((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] ?? 'Sin nombre';
                        return Text(
                          'Dr. $name',
                          overflow: TextOverflow.ellipsis,
                        );
                      }).toList();
                    },
                    onChanged: (String? newValue) async {
                      if (newValue != null) {
                        final doctorDoc = doctors.firstWhere(
                          (doc) => doc.id == newValue,
                        );
                        final doctorData =
                            doctorDoc.data() as Map<String, dynamic>;
                        setState(() {
                          _selectedDoctorId = newValue;
                          _selectedDoctorName =
                              'Dr. ${doctorData['name'] ?? 'Doctor'}';
                          _selectedDate = null;
                          _selectedTime = null;
                          _availableTimes = [];
                        });
                        await _loadDoctorWorkDays();
                      }
                    },
                    validator: (value) =>
                        value == null ? 'Selecciona un doctor' : null,
                  );
                },
              ),
              const SizedBox(height: 20),

              // Selector de Fecha
              ListTile(
                title: Text(
                  'Fecha de la Cita',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                subtitle: Text(
                  _selectedDate == null
                      ? 'Seleccionar Fecha'
                      : DateFormat('dd MMMM yyyy', 'es').format(_selectedDate!),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                leading: Icon(Icons.calendar_today, color: primaryColor),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _selectDate,
                enabled: _selectedDoctorId != null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 20),

              // Lista de Horas Disponibles
              if (_selectedDate != null) ...[
                if (_isLoadingTimes)
                  const Center(child: CircularProgressIndicator())
                else if (_availableTimes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'No hay horarios disponibles para esta fecha',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Icon(Icons.access_time, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Horarios Disponibles (${_availableTimes.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _availableTimes.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final time = _availableTimes[index];
                        final isSelected = _selectedTime == time;

                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          selectedTileColor: primaryColor.withOpacity(0.1),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor
                                  : primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.schedule,
                              size: 20,
                              color: isSelected ? Colors.white : primaryColor,
                            ),
                          ),
                          title: Text(
                            time.format(context),
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? primaryColor : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: primaryColor)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedTime = time;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],

              // Motivo de la Consulta
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Motivo de la consulta',
                  hintText: 'Ej: Control anual, Dolor de garganta, etc.',
                  prefixIcon: Icon(Icons.notes, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Ingresa el motivo de la consulta' : null,
              ),
              const SizedBox(height: 30),

              // Botón de Guardar
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : _saveAppointment, // ← CAMBIAR ESTA LÍNEA
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaving
                      ? Colors.grey
                      : primaryColor, // ← AGREGAR
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child:
                    _isSaving // ← AGREGAR ESTE CONDICIONAL
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Agendando...',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ],
                      )
                    : const Text(
                        'Confirmar Cita',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
