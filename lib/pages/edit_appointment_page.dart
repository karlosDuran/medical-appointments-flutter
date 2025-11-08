import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

class EditAppointmentPage extends StatefulWidget {
  final String docId;
  const EditAppointmentPage({super.key, required this.docId});

  @override
  State<EditAppointmentPage> createState() => _EditAppointmentPageState();
}

class _EditAppointmentPageState extends State<EditAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedSpecialist;
  bool _isLoading = true;

  final Color primaryColor = const Color(0xFF007BFF);

  // Lista de especialistas (debería venir de Firestore)
  final List<String> _specialists = [
    'Dr. Juan Pérez - Cardiología',
    'Dra. María Ríos - Pediatría',
    'Dr. Carlos López - General',
  ];

  @override
  void initState() {
    super.initState();
    _loadAppointmentData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // Cargar datos existentes de la cita
  Future<void> _loadAppointmentData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.docId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final startTime = (data['start_time'] as Timestamp).toDate();

        setState(() {
          _reasonController.text = data['reason'] ?? '';
          _selectedDate = startTime;
          _selectedTime = TimeOfDay.fromDateTime(startTime);
          _selectedSpecialist = data['specialist'];
          _isLoading = false;
        });
      }
    } catch (e) {
      _showMessage('Error al cargar la cita: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
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
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _updateAppointment() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null) {
      final finalDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final endDateTime = finalDateTime.add(const Duration(minutes: 30));

      try {
        await FirestoreService().updateAppointment(widget.docId, {
          'reason': _reasonController.text.trim(),
          'start_time': Timestamp.fromDate(finalDateTime),
          'end_time': Timestamp.fromDate(endDateTime),
          'specialist': _selectedSpecialist,
        });

        if (mounted) {
          _showMessage('Cita actualizada exitosamente');
          Navigator.pop(context);
        }
      } catch (e) {
        _showMessage('Error al actualizar: $e');
      }
    } else {
      _showMessage('Por favor completa todos los campos');
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Editar Cita'),
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
              // Especialista
              DropdownButtonFormField<String>(
                initialValue: _selectedSpecialist,
                decoration: InputDecoration(
                  labelText: 'Especialista',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _specialists.map((spec) {
                  return DropdownMenuItem(value: spec, child: Text(spec));
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedSpecialist = value),
                validator: (value) =>
                    value == null ? 'Selecciona un especialista' : null,
              ),
              const SizedBox(height: 16),

              // Fecha
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedDate != null
                        ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                        : 'Selecciona una fecha',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Hora
              InkWell(
                onTap: _selectTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Hora',
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedTime != null
                        ? _selectedTime!.format(context)
                        : 'Selecciona una hora',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Motivo
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Motivo de la consulta',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingresa el motivo' : null,
              ),
              const SizedBox(height: 24),

              // Botón actualizar
              ElevatedButton(
                onPressed: _updateAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Actualizar Cita',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
