import 'package:flutter/material.dart';

// Modelo de datos para una cita
class Appointment {
  final String specialist;
  final DateTime date;
  final TimeOfDay time;

  Appointment({
    required this.specialist,
    required this.date,
    required this.time,
  });
}

// Clase estática para simular el almacenamiento de datos (registro)
class AppointmentManager {
  // Lista donde se guardan todas las citas
  static final List<Appointment> _appointments = [];

  // Método para añadir una nueva cita
  static void addAppointment(Appointment appointment) {
    _appointments.add(appointment);
    // Opcionalmente, aquí se podría ordenar la lista por fecha y hora
  }

  // Método para obtener todas las citas
  static List<Appointment> get appointments => _appointments;
}
