import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
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

  // Variables de estado para la cita
  String? _selectedSpecialist;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _reasonController = TextEditingController();

  final Color primaryColor = const Color(0xFF007BFF);

  // Lista de especialistas simulada (debería venir de Firestore)
  final List<String> _specialists = [
    'Dr. Juan Pérez - Cardiología',
    'Dra. María Ríos - Pediatría',
    'Dr. Carlos López - General',
  ];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
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
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
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
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveAppointment() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        _showMessage("Error de autenticación. Por favor, reinicia la sesión.");
        return;
      }

      // Combinar fecha y hora en un solo DateTime
      final finalDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Simular una duración de 30 minutos
      final endTime = finalDateTime.add(const Duration(minutes: 30));

      final appointmentData = {
        'patient_id': userId,
        'doctor_id': 'DOC-123', // ID de doctor simulado
        'specialist_name': _selectedSpecialist,
        'start_time': Timestamp.fromDate(finalDateTime),
        'end_time': Timestamp.fromDate(endTime),
        'reason': _reasonController.text.trim(),
        'type': widget.appointmentType,
        'status': 'agendada',
        'created_at': Timestamp.now(),
      };

      try {
        await FirestoreService().createAppointment(appointmentData);
        _showMessage("Cita agendada con éxito.");

        // Navegar de vuelta a la vista de citas agendadas
        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.home);
        }
      } catch (e) {
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

              // 1. Selector de Especialista
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Especialista',
                  prefixIcon: Icon(Icons.person_pin, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                value: _selectedSpecialist,
                hint: const Text('Selecciona un doctor'),
                items: _specialists.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSpecialist = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Selecciona un especialista' : null,
              ),
              const SizedBox(height: 20),

              // 2. Selector de Fecha
              ListTile(
                title: Text(
                  'Fecha de la Cita',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                subtitle: Text(
                  _selectedDate == null
                      ? 'Seleccionar Fecha'
                      : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                leading: Icon(Icons.calendar_today, color: primaryColor),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _selectDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Selector de Hora (con reloj)
              ListTile(
                title: Text(
                  'Hora de la Cita',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                subtitle: Text(
                  _selectedTime == null
                      ? 'Seleccionar Hora'
                      : _selectedTime!.format(context),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                leading: Icon(Icons.access_time, color: primaryColor),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _selectTime,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Motivo de la Consulta
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
                onPressed: _saveAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: const Text(
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
