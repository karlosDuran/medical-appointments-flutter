import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/appointment_manager.dart'; // Importar el gestor de citas

// Lista simulada de especialistas
const List<String> specialists = [
  'Cardiología',
  'Pediatría',
  'Dermatología',
  'Neurología',
];

class ScheduleAppointmentPage extends StatefulWidget {
  const ScheduleAppointmentPage({super.key});

  @override
  State<ScheduleAppointmentPage> createState() =>
      _ScheduleAppointmentPageState();
}

class _ScheduleAppointmentPageState extends State<ScheduleAppointmentPage> {
  String? _selectedSpecialist;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final Color primaryColor = const Color(0xFF007BFF);
  final DateFormat dateFormatter = DateFormat('EEE, MMM d, yyyy');

  // Lógica para elegir fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: primaryColor,
            colorScheme: ColorScheme.light(primary: primaryColor),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Lógica para elegir la hora usando el selector de reloj (showTimePicker)
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Lógica para guardar la cita (Ahora guarda en el gestor estático)
  void _saveAppointment() {
    if (_selectedSpecialist == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, selecciona Especialista, Fecha y Hora."),
        ),
      );
      return;
    }

    // Crea el nuevo objeto Cita
    final newAppointment = Appointment(
      specialist: _selectedSpecialist!,
      date: _selectedDate!,
      time: _selectedTime!,
    );

    // --- GUARDADO REAL EN EL GESTOR ESTÁTICO ---
    AppointmentManager.addAppointment(newAppointment);

    // Muestra confirmación
    final String formattedTime = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(_selectedTime!, alwaysUse24HourFormat: false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "¡Cita con $_selectedSpecialist agendada para el ${dateFormatter.format(_selectedDate!)} a las $formattedTime!",
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    // Vuelve a la pantalla anterior (HomePage)
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Helper para formatear la hora seleccionada para mostrarla en el UI
    final String timeDisplay = _selectedTime == null
        ? "Selecciona una hora"
        : MaterialLocalizations.of(
            context,
          ).formatTimeOfDay(_selectedTime!, alwaysUse24HourFormat: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Agendar Cita",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Selecciona los detalles de tu consulta",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 30),

            // 1. Especialista
            const Text(
              "Especialista",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.person_pin, color: primaryColor),
              ),
              value: _selectedSpecialist,
              hint: const Text("Selecciona un área"),
              items: specialists.map((String value) {
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
            ),
            const SizedBox(height: 25),

            // 2. Fecha
            const Text(
              "Fecha de Cita",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
                ),
                child: Text(
                  _selectedDate == null
                      ? "Selecciona una fecha"
                      : dateFormatter.format(_selectedDate!),
                  style: TextStyle(
                    color: _selectedDate == null ? Colors.grey : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // 3. Hora (Usando showTimePicker)
            const Text(
              "Hora de Cita",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectTime(
                context,
              ), // CAMBIO: Llama a la función del selector de reloj
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.access_time, color: primaryColor),
                ),
                child: Text(
                  timeDisplay,
                  style: TextStyle(
                    color: _selectedTime == null ? Colors.grey : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Botón de Guardar
            ElevatedButton.icon(
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                "Confirmar Cita",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              onPressed: _saveAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
